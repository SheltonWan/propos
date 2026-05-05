import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/business_rules.dart';
import '../../domain/entities/heatmap.dart';

/// SVG 楼层图本地缓存服务。
///
/// 提供两级缓存：
/// - **文件系统 SVG 缓存**（跨重启有效）：以 `floorId` 为键，`updatedAt` 为版本校验标志，
///   存储于 `{appDocDir}/propos_cache/svg/`。超过 [BusinessRules.svgCacheMaxEntries]
///   条时按 LRU（最后修改时间最旧）淘汰。
/// - **内存热区缓存**（TTL [BusinessRules.heatmapCacheTtlMinutes] 分钟）：
///   App 生命周期内有效，TTL 到期后调用方需重新 fetch。
///
/// 此类无 Flutter SDK 依赖，可在纯 Dart 环境下做单元测试。
class FloorMapCacheService {
  // ── 热区内存缓存 ──────────────────────────────────────────────────────────────
  final Map<String, _HeatmapEntry> _heatmapCache = {};

  // ── SVG 文件系统缓存 ──────────────────────────────────────────────────────────
  Directory? _cacheDir;

  // ── 热区缓存公开接口 ──────────────────────────────────────────────────────────

  /// 从内存缓存读取热区数据。
  ///
  /// 若缓存不存在或已过 TTL，返回 `null`，调用方需重新 fetch。
  FloorHeatmap? getHeatmap(String floorId) {
    final entry = _heatmapCache[floorId];
    if (entry == null) return null;
    final age = DateTime.now().difference(entry.fetchedAt).inMinutes;
    if (age >= BusinessRules.heatmapCacheTtlMinutes) {
      _heatmapCache.remove(floorId);
      return null;
    }
    return entry.data;
  }

  /// 将热区数据写入内存缓存，记录写入时间用于 TTL 校验。
  void putHeatmap(String floorId, FloorHeatmap data) {
    _heatmapCache[floorId] = _HeatmapEntry(data: data, fetchedAt: DateTime.now());
  }

  // ── SVG 文件系统缓存公开接口 ──────────────────────────────────────────────────

  /// 读取 SVG 文件系统缓存。
  ///
  /// 仅当 [updatedAt] 与元数据中记录的版本一致时命中，否则返回 `null`。
  /// [updatedAt] 传入 `null` 表示后端未提供版本信息，始终返回 `null`（强制重新下载）。
  Future<String?> getSvg(String floorId, DateTime? updatedAt) async {
    if (updatedAt == null) return null;

    final dir = await _getCacheDir();
    final svgFile = File('${dir.path}/$floorId.svg');
    final metaFile = File('${dir.path}/$floorId.meta.json');

    if (!svgFile.existsSync() || !metaFile.existsSync()) return null;

    try {
      final meta = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      final cachedUpdatedAt = meta['updatedAt'] as String?;
      // 版本不匹配 → 缓存失效
      if (cachedUpdatedAt != updatedAt.toIso8601String()) return null;
      return await svgFile.readAsString();
    } catch (_) {
      // 元数据损坏，视为缓存缺失
      return null;
    }
  }

  /// 将 SVG 内容写入文件系统缓存，并更新元数据。
  ///
  /// 写入完成后自动检查是否超过 [BusinessRules.svgCacheMaxEntries]，
  /// 超出则淘汰最旧的缓存文件（LRU by file modified time）。
  Future<void> putSvg(
    String floorId,
    DateTime updatedAt,
    String svgContent,
  ) async {
    final dir = await _getCacheDir();
    final svgFile = File('${dir.path}/$floorId.svg');
    final metaFile = File('${dir.path}/$floorId.meta.json');

    await svgFile.writeAsString(svgContent);
    await metaFile.writeAsString(jsonEncode({
      'updatedAt': updatedAt.toIso8601String(),
      'cachedAt': DateTime.now().toIso8601String(),
    }));

    await _evictOldest(dir);
  }

  /// 删除指定楼层的 SVG 文件系统缓存（版本更新时由外部显式调用）。
  Future<void> removeSvg(String floorId) async {
    final dir = await _getCacheDir();
    final svgFile = File('${dir.path}/$floorId.svg');
    final metaFile = File('${dir.path}/$floorId.meta.json');
    if (svgFile.existsSync()) await svgFile.delete();
    if (metaFile.existsSync()) await metaFile.delete();
  }

  // ── 私有方法 ──────────────────────────────────────────────────────────────────

  /// 懒初始化并返回 SVG 缓存目录，不存在时自动创建。
  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/propos_cache/svg');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  /// LRU 淘汰：当 SVG 条目数超过上限时，删除最久未访问（最后修改时间最旧）的文件。
  Future<void> _evictOldest(Directory dir) async {
    // 收集所有 .svg 文件（不含 .meta.json）
    final svgFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .toList();

    if (svgFiles.length <= BusinessRules.svgCacheMaxEntries) return;

    // 按最后修改时间升序排序，删除最旧的超出部分
    svgFiles.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    final excess = svgFiles.length - BusinessRules.svgCacheMaxEntries;
    for (var i = 0; i < excess; i++) {
      final svgFile = svgFiles[i];
      // 同时删除对应 .meta.json
      final metaPath = svgFile.path.replaceAll(RegExp(r'\.svg$'), '.meta.json');
      if (svgFile.existsSync()) await svgFile.delete();
      final metaFile = File(metaPath);
      if (metaFile.existsSync()) await metaFile.delete();
    }
  }
}

/// 热区内存缓存条目（内部使用）。
class _HeatmapEntry {
  final FloorHeatmap data;
  final DateTime fetchedAt;

  const _HeatmapEntry({required this.data, required this.fetchedAt});
}
