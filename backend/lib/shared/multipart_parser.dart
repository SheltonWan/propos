import 'dart:convert';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

import '../core/errors/app_exception.dart';

/// multipart/form-data 解析工具
///
/// 约定：
///   - `fields`：文本字段，值为 String
///   - `files`：二进制字段，值为 `UploadedFile`
///   - 调用者负责限制文件大小（在 AppConfig.maxUploadSizeMb 范围内）
class MultipartParser {
  /// 从 Shelf Request 解析所有 multipart 字段
  ///
  /// 返回 `ParsedMultipart`，包含文本字段和文件字段
  static Future<ParsedMultipart> parse(Request request) async {
    final contentType = request.headers['content-type'] ?? '';
    final boundary = _extractBoundary(contentType);
    if (boundary == null) {
      throw const ValidationException(
          'VALIDATION_ERROR', '请求 Content-Type 缺少 boundary 参数');
    }

    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(request.read()).toList();

    final fields = <String, String>{};
    final files = <String, UploadedFile>{};

    for (final part in parts) {
      final disposition = part.headers['content-disposition'] ?? '';
      final name = _extractParam(disposition, 'name');
      if (name == null) continue;

      final filename = _extractParam(disposition, 'filename');
      final bytes = await part.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );

      if (filename != null) {
        files[name] = UploadedFile(
          filename: filename,
          bytes: bytes,
          contentType: part.headers['content-type'],
        );
      } else {
        fields[name] = utf8.decode(bytes).trim();
      }
    }

    return ParsedMultipart(fields: fields, files: files);
  }

  /// 从 Content-Type 头提取 boundary 值
  static String? _extractBoundary(String contentType) {
    final match = RegExp(r'boundary=([^\s;]+)').firstMatch(contentType);
    return match?.group(1);
  }

  /// 从 Content-Disposition 头提取指定参数值（不含引号）
  static String? _extractParam(String header, String param) {
    final pattern = RegExp('$param="([^"]*)"');
    final match = pattern.firstMatch(header);
    if (match != null) return match.group(1);
    // 尝试无引号形式
    final pattern2 = RegExp('$param=([^;\\s]+)');
    return pattern2.firstMatch(header)?.group(1);
  }
}

/// 已解析的 multipart 数据
class ParsedMultipart {
  final Map<String, String> fields;
  final Map<String, UploadedFile> files;

  const ParsedMultipart({required this.fields, required this.files});

  /// 获取必填文本字段，不存在则抛出 VALIDATION_ERROR
  String requireField(String name) {
    final v = fields[name];
    if (v == null || v.isEmpty) {
      throw ValidationException('VALIDATION_ERROR', '缺少必填字段: $name');
    }
    return v;
  }

  /// 获取可选文本字段
  String? optionalField(String name) => fields[name];

  /// 获取必填文件字段，不存在则抛出 VALIDATION_ERROR
  UploadedFile requireFile(String name) {
    final f = files[name];
    if (f == null) {
      throw ValidationException('VALIDATION_ERROR', '缺少必填文件: $name');
    }
    return f;
  }
}

/// 上传文件数据载体
class UploadedFile {
  final String filename;
  final List<int> bytes;
  final String? contentType;

  const UploadedFile({
    required this.filename,
    required this.bytes,
    this.contentType,
  });
}
