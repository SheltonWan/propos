import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/constants/business_rules.dart';
import '../../data/services/floor_map_cache_service.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/repositories/assets_repository.dart';
import 'floor_map_state.dart';

/// 楼层平面图页 Cubit。
///
/// 支持两种初始化方式：
///   - [fetch]：直接加载指定 floorId（路由传参时使用）
///   - [loadByBuilding]：先加载楼栋楼层列表，再加载指定层（或第一层）
///
/// 楼层切换通过 [selectFloor] 实现，采用 **Hold & Replace** 策略：
///   - 若目标楼层双缓存（SVG 文件系统 + 热区内存）均命中，直接 emit loaded，无任何 loading 闪烁；
///   - 否则保留当前已渲染内容（`isSwitching: true`），后台并发请求新数据，就绪后平滑替换。
///
/// 加载完成后自动后台预加载相邻 [BusinessRules.svgPreloadAdjacentCount] 层，
/// 提升连续楼层切换的响应速度。
class FloorMapCubit extends Cubit<FloorMapState> {
  final AssetsRepository _repository;
  final FloorMapCacheService _cache;

  /// 热区请求序号，用于忽略已过期（被更新请求覆盖）的响应。
  int _heatmapRequestSeq = 0;

  FloorMapCubit(this._repository, this._cache)
      : super(const FloorMapState.initial());

  // ── 公开方法 ───────────────────────────────────────────────────────────────

  /// 加载指定 [floorId] 的楼层信息 + 热区数据 + SVG。
  ///
  /// 若当前 state 已有楼层列表，则保留（不重复请求楼层目录）。
  /// 通常由 [selectFloor] 或路由直接传参时调用。
  Future<void> fetch(String floorId) async {
    final prevLoaded = switch (state) {
      FloorMapStateLoaded() => state as FloorMapStateLoaded,
      _ => null,
    };
    final prevFloors = prevLoaded?.floors ?? <Floor>[];

    // 若已有缓存且非切换中，进入 Hold & Replace 模式；否则全屏 loading。
    if (prevLoaded != null) {
      emit(prevLoaded.copyWith(
        isSwitching: true,
        switchingToFloorId: floorId,
      ));
    } else {
      emit(const FloorMapState.loading());
    }

    final seq = ++_heatmapRequestSeq;

    try {
      // 并发：楼层详情 + 热区（检查内存缓存）
      final floorFuture = _repository.fetchFloor(floorId);

      // 先检查热区内存缓存
      FloorHeatmap? cachedHeatmap = _cache.getHeatmap(floorId);
      final heatmapFuture = cachedHeatmap != null
          ? Future.value(cachedHeatmap)
          : _repository.fetchFloorHeatmap(floorId);

      final Floor floor = await floorFuture;

      // 过期检测：若在 await 期间又触发了更新的请求，忽略本次结果
      if (seq != _heatmapRequestSeq) return;

      final FloorHeatmap heatmap = await heatmapFuture;
      if (seq != _heatmapRequestSeq) return;

      // 写入热区内存缓存（仅在实际 fetch 时才写入，避免覆写更新的缓存）
      if (cachedHeatmap == null) _cache.putHeatmap(floorId, heatmap);

      // 补充楼层列表（首次进入时）
      List<Floor> floors = prevFloors;
      if (floors.isEmpty) {
        try {
          floors = await _repository.fetchFloors(floor.buildingId);
        } catch (_) {
          // 拉取失败不阻断主流程，标签栏隐藏即可
        }
      }

      // 获取 SVG（先查文件系统缓存）
      final svgContent = await _loadSvgWithCache(floor, heatmap.svgPath);
      if (seq != _heatmapRequestSeq) return;

      emit(FloorMapState.loaded(
        floor: floor,
        heatmap: heatmap,
        svgContent: svgContent,
        floors: floors,
      ));

      // 加载成功后异步预加载相邻楼层
      _preloadAdjacentFloors(floors, floor.id);
    } on ApiException catch (e) {
      if (seq != _heatmapRequestSeq) return;
      if (e.code == 'SVG_DOWNLOAD_CANCELLED') return; // 切换触发的取消，不显示错误
      emit(FloorMapState.error(e.message));
    } catch (e) {
      if (seq != _heatmapRequestSeq) return;
      emit(const FloorMapState.error('操作失败，请重试'));
    }
  }

  /// 先按 [buildingId] 拉取楼层列表，再加载 [initialFloorId]（或列表第一层）的数据。n  ///
  /// 页面首次进入时调用。
  Future<void> loadByBuilding(
    String buildingId, {
    String? initialFloorId,
  }) async {
    emit(const FloorMapState.loading());
    _heatmapRequestSeq++; // 使所有旧的 fetch 序列失效

    try {
      final floors = await _repository.fetchFloors(buildingId);
      if (floors.isEmpty) {
        emit(const FloorMapState.error('该楼栋暂无楼层数据'));
        return;
      }
      final targetFloor = floors.firstWhere(
        (f) => f.id == initialFloorId,
        orElse: () => floors.first,
      );

      final seq = ++_heatmapRequestSeq;

      FloorHeatmap? cachedHeatmap = _cache.getHeatmap(targetFloor.id);
      final heatmapFuture = cachedHeatmap != null
          ? Future.value(cachedHeatmap)
          : _repository.fetchFloorHeatmap(targetFloor.id);

      final heatmap = await heatmapFuture;
      if (seq != _heatmapRequestSeq) return;

      if (cachedHeatmap == null) _cache.putHeatmap(targetFloor.id, heatmap);

      final svgContent = await _loadSvgWithCache(targetFloor, heatmap.svgPath);
      if (seq != _heatmapRequestSeq) return;

      emit(FloorMapState.loaded(
        floor: targetFloor,
        heatmap: heatmap,
        svgContent: svgContent,
        floors: floors,
      ));

      _preloadAdjacentFloors(floors, targetFloor.id);
    } on ApiException catch (e) {
      emit(FloorMapState.error(e.message));
    } catch (e) {
      emit(const FloorMapState.error('操作失败，请重试'));
    }
  }

  /// 切换到另一楼层（Hold & Replace 策略）。
  ///
  /// - 同一楼层：直接返回，无任何状态变更。
  /// - 双缓存命中：直接 emit loaded，无任何 loading 闪烁。
  /// - 缓存未命中：取消当前 SVG 下载，emit isSwitching，后台并发请求。
  Future<void> selectFloor(String floorId) async {
    if (state case FloorMapStateLoaded(:final floor) when floor.id == floorId) {
      return; // 已是当前楼层，无需重复加载
    }

    // 取消正在进行的 SVG 下载（旧楼层的下载请求）
    _repository.cancelFloorSvgDownload();

    // 尝试双缓存快速命中
    if (state case FloorMapStateLoaded(:final floors, :final floor)) {
      final cachedHeatmap = _cache.getHeatmap(floorId);
      final targetFloor = floors.firstWhere(
        (f) => f.id == floorId,
        orElse: () => floor, // 理论上不会找不到，防御性 fallback
      );
      if (cachedHeatmap != null) {
        final cachedSvg = await _cache.getSvg(targetFloor.id, targetFloor.updatedAt);
        if (cachedSvg != null) {
          // 双缓存命中，直接渲染，零 loading 闪烁
          _heatmapRequestSeq++;
          emit(FloorMapState.loaded(
            floor: targetFloor,
            heatmap: cachedHeatmap,
            svgContent: cachedSvg,
            floors: floors,
          ));
          return;
        }
      }
    }

    // 缓存未命中，走 Hold & Replace 模式
    await fetch(floorId);
  }

  @override
  Future<void> close() {
    _repository.cancelFloorSvgDownload();
    return super.close();
  }

  // ── 私有方法 ───────────────────────────────────────────────────────────────

  /// 获取 SVG 内容：优先查文件系统缓存，缓存未命中时下载并写入缓存。
  ///
  /// [svgPath] 为 `null`（该楼层无平面图）时返回空字符串。
  Future<String> _loadSvgWithCache(Floor floor, String? svgPath) async {
    if (svgPath == null) return '';

    // 查文件系统缓存（以 floor.updatedAt 作版本校验）
    final cached = await _cache.getSvg(floor.id, floor.updatedAt);
    if (cached != null) return cached;

    // 缓存未命中：下载 SVG
    final svgContent = await _repository.fetchFloorSvg(svgPath);

    // 异步写入缓存（不阻塞 UI 渲染）
    if (svgContent.isNotEmpty) {
      _cache.putSvg(floor.id, floor.updatedAt, svgContent).ignore();
    }

    return svgContent;
  }

  /// 后台预加载相邻楼层的热区数据和 SVG（写入缓存，不 emit 状态）。
  ///
  /// 延迟 500ms 执行，避免与主请求竞争带宽。
  /// 加载失败时静默忽略（预加载失败不影响正常切换流程）。
  void _preloadAdjacentFloors(List<Floor> floors, String currentFloorId) {
    final currentIdx = floors.indexWhere((f) => f.id == currentFloorId);
    if (currentIdx < 0) return;

    const n = BusinessRules.svgPreloadAdjacentCount;
    final start = (currentIdx - n).clamp(0, floors.length - 1);
    final end = (currentIdx + n).clamp(0, floors.length - 1);

    Future.delayed(const Duration(milliseconds: 500), () async {
      for (var i = start; i <= end; i++) {
        if (i == currentIdx) continue;
        final target = floors[i];

        // 热区缓存
        if (_cache.getHeatmap(target.id) == null) {
          try {
            final heatmap = await _repository.fetchFloorHeatmap(target.id);
            _cache.putHeatmap(target.id, heatmap);
            // SVG 缓存（使用热区返回的 svgPath）
            final cachedSvg = await _cache.getSvg(target.id, target.updatedAt);
            if (cachedSvg == null && heatmap.svgPath != null) {
              final svgContent = await _repository.fetchFloorSvg(heatmap.svgPath!);
              if (svgContent.isNotEmpty) {
                await _cache.putSvg(target.id, target.updatedAt, svgContent);
              }
            }
          } catch (_) {
            // 预加载失败静默忽略
          }
        } else {
          // 热区已缓存，仅检查 SVG
          final cachedSvg = await _cache.getSvg(target.id, target.updatedAt);
          if (cachedSvg == null) {
            try {
              final heatmap = _cache.getHeatmap(target.id)!;
              if (heatmap.svgPath != null) {
                final svgContent = await _repository.fetchFloorSvg(heatmap.svgPath!);
                if (svgContent.isNotEmpty) {
                  await _cache.putSvg(target.id, target.updatedAt, svgContent);
                }
              }
            } catch (_) {
              // 预加载失败静默忽略
            }
          }
        }
      }
    });
  }
}



