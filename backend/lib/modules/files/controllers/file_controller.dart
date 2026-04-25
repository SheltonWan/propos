import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../shared/multipart_parser.dart';
import '../services/file_service.dart';

/// FileController — 通用文件代理与上传路由处理器。
///
/// 端点：
///   GET  /api/files/<path>  — 代理下载附件或图纸
///   POST /api/files         — 通用文件上传，返回 { storage_path, file_size_kb, content_type }
///
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class FileController {
  final FileService _service;

  FileController(this._service);

  Router get router {
    final r = Router();
    // 多段路径：使用正则匹配捕获完整子路径
    r.get('/files/<path|.*>', _download);
    r.post('/files', _upload);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// GET /api/files/<path>
  /// 直接以二进制返回文件内容；浏览器可内联渲染（SVG/PNG）或下载
  Future<Response> _download(Request request, String path) async {
    final result = await _service.readFile(path);
    return Response.ok(
      result.bytes,
      headers: {
        'content-type': result.contentType,
        // 允许浏览器内联展示（SVG/图片），同时便于另存为
        'content-disposition': 'inline; filename="${result.fileName}"',
        'cache-control': 'private, max-age=300',
      },
    );
  }

  /// POST /api/files
  /// Content-Type: multipart/form-data
  /// Fields: category?; Files: file
  Future<Response> _upload(Request request) async {
    final parsed = await MultipartParser.parse(request);
    final file = parsed.requireFile('file');
    final category = parsed.optionalField('category') ?? 'misc';

    final saved = await _service.saveUpload(
      fileBytes: file.bytes,
      originalFilename: file.filename,
      category: category,
    );

    return Response(
      201,
      body: jsonEncode({'data': saved}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
