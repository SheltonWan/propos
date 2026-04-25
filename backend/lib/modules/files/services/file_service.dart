import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';

/// FileService — 文件代理读取与通用上传。
///
/// 安全约束：
///   1. 所有相对路径必须在 _fileStoragePath 根目录之下，禁止 `..` 穿越
///   2. 上传文件保存在 `uploads/{category}/{uuid}_{safeFilename}`
///   3. 不直接返回 Response，错误统一通过 AppException 抛出
class FileService {
  final String _fileStoragePath;
  final int _maxUploadSizeMb;
  final _uuid = const Uuid();

  FileService(this._fileStoragePath, {int maxUploadSizeMb = 50})
      : _maxUploadSizeMb = maxUploadSizeMb;

  /// 解析相对路径到绝对路径，并校验不越界
  String _resolveSafe(String relPath) {
    if (relPath.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', '文件路径不能为空');
    }
    final normalized = p.normalize(relPath);
    // 拒绝绝对路径与上溯
    if (p.isAbsolute(normalized) ||
        normalized.startsWith('..') ||
        normalized.contains('${p.separator}..${p.separator}')) {
      throw const ValidationException('INVALID_FILE_PATH', '非法文件路径');
    }
    final abs = p.normalize(p.join(_fileStoragePath, normalized));
    // 二次校验：解析后的绝对路径必须仍在存储根目录之下
    if (!p.isWithin(_fileStoragePath, abs)) {
      throw const ValidationException('INVALID_FILE_PATH', '非法文件路径');
    }
    return abs;
  }

  /// 读取文件，不存在则抛 FILE_NOT_FOUND
  Future<({List<int> bytes, String contentType, String fileName})> readFile(
      String relPath) async {
    final abs = _resolveSafe(relPath);
    final file = File(abs);
    if (!await file.exists()) {
      throw const NotFoundException('FILE_NOT_FOUND', '文件不存在');
    }
    final bytes = await file.readAsBytes();
    final fileName = p.basename(abs);
    final contentType =
        lookupMimeType(abs, headerBytes: bytes.length > 16 ? bytes.sublist(0, 16) : bytes) ??
            'application/octet-stream';
    return (bytes: bytes, contentType: contentType, fileName: fileName);
  }

  /// 通用文件上传：保存到 uploads/{category}/{uuid}_{safeName}
  /// 返回存储相对路径、大小、内容类型
  Future<Map<String, dynamic>> saveUpload({
    required List<int> fileBytes,
    required String originalFilename,
    String category = 'misc',
  }) async {
    if (fileBytes.isEmpty) {
      throw const ValidationException('VALIDATION_ERROR', '上传文件为空');
    }
    final maxBytes = _maxUploadSizeMb * 1024 * 1024;
    if (fileBytes.length > maxBytes) {
      throw ValidationException(
          'FILE_TOO_LARGE', '文件大小超出限制（最大 $_maxUploadSizeMb MB）');
    }
    // category 仅允许字母数字与连字符
    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(category)) {
      throw const ValidationException('VALIDATION_ERROR', '非法的 category 值');
    }

    final safeName = _sanitizeFilename(originalFilename);
    final id = _uuid.v4();
    final relDir = p.join('uploads', category);
    final relPath = p.join(relDir, '${id}_$safeName');

    final absDir = Directory(p.join(_fileStoragePath, relDir));
    await absDir.create(recursive: true);
    final absFile = File(p.join(_fileStoragePath, relPath));
    await absFile.writeAsBytes(Uint8List.fromList(fileBytes));

    final contentType = lookupMimeType(safeName,
            headerBytes: fileBytes.length > 16 ? fileBytes.sublist(0, 16) : fileBytes) ??
        'application/octet-stream';

    return {
      'storage_path': relPath.replaceAll(r'\', '/'),
      'file_size_kb': (fileBytes.length / 1024).ceil(),
      'content_type': contentType,
    };
  }

  /// 文件名安全化：去除路径分隔符、不可见字符
  String _sanitizeFilename(String name) {
    final base = p.basename(name);
    final cleaned = base.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return 'file';
    }
    // 限制长度
    return cleaned.length > 120 ? cleaned.substring(cleaned.length - 120) : cleaned;
  }
}
