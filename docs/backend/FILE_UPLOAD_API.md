# 文件上传 API 详细设计

> **文档版本**: v1.0
> **更新日期**: 2026-04-08
> **补充对象**: API_CONTRACT_v1.7.md §文件管理模块

---

## 一、通用约定

| 项目 | 规则 |
|------|------|
| 传输格式 | `multipart/form-data` |
| 最大单文件 | `MAX_UPLOAD_SIZE_MB` 环境变量控制（默认 50 MB） |
| 允许类型 | 按端点限制（见下方各端点详情） |
| 文件名处理 | 原始文件名仅记录在 metadata 中，存储路径使用 UUID + 业务规则路径 |
| 路径规则 | 不含业务编号，全部使用 UUID 构造（防止编号变更导致路径失效） |
| 访问方式 | `GET /api/files/{path}` 代理访问，不直接暴露存储地址 |

---

## 二、端点详情

### 2.1 `POST /api/files` — 通用文件上传

**权限**: 已登录

**Request** — `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 文件二进制内容 |
| `category` | string | 是 | 分类：`contract` / `workorder` / `renovation` / `floor_cad` / `other` |
| `resource_id` | string(uuid) | 否 | 关联资源 ID（合同/工单/改造记录等） |

**Response 201**

```json
{
  "data": {
    "storage_path": "contracts/e0000000-.../signed.pdf",
    "original_name": "合同扫描件.pdf",
    "size_bytes": 2048576,
    "mime_type": "application/pdf",
    "uploaded_at": "2026-04-08T10:00:00Z"
  }
}
```

**错误码**

| 错误码 | HTTP | 说明 |
|--------|------|------|
| `FILE_TOO_LARGE` | 413 | 超过 `MAX_UPLOAD_SIZE_MB` 限制 |
| `FILE_TYPE_NOT_ALLOWED` | 415 | 文件类型不在允许列表中 |
| `UPLOAD_FAILED` | 500 | 服务端存储失败 |

---

### 2.2 `POST /api/floors/:id/cad` — 上传 CAD 图纸并触发转换

**权限**: `assets.write`

**Request** — `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | `.dwg` 文件 |

**允许类型**: `.dwg`（MIME: `application/acad` 或 `application/octet-stream`）

**处理流程**:
1. 保存原始 `.dwg` 文件
2. 调用 ODA File Converter: `.dwg` → `.dxf`
3. 调用 Python ezdxf: `.dxf` → `.svg` + `.png`
4. 写入 `floors.svg_path` / `png_path`
5. 创建 `floor_plans` 记录（`is_current = true`）

**Response 201**

```json
{
  "data": {
    "floor_id": "b0000000-...",
    "svg_path": "floors/a0000000-.../b0000000-....svg",
    "png_path": "floors/a0000000-.../b0000000-....png",
    "version_label": "2026-04-08 上传",
    "is_current": true
  }
}
```

**错误码**

| 错误码 | HTTP | 说明 |
|--------|------|------|
| `INVALID_CAD_FILE` | 400 | 不是有效的 DWG 文件 |
| `CAD_CONVERSION_FAILED` | 500 | DWG → SVG 转换失败 |
| `FLOOR_NOT_FOUND` | 404 | 楼层不存在 |

---

### 2.3 `POST /api/contracts/:id/attachments` — 上传合同附件

**权限**: `contract.write`

**Request** — `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 附件文件 |
| `attachment_type` | string | 是 | `signed_pdf` / `amendment` / `supplement` / `other` |
| `description` | string | 否 | 附件说明 |

**允许类型**: `.pdf`, `.jpg`, `.jpeg`, `.png`（MIME 白名单校验）

**存储路径**: `contracts/{contract_id}/{attachment_type}_{timestamp}.{ext}`

**Response 201**

```json
{
  "data": {
    "id": "uuid",
    "contract_id": "e0000000-...",
    "attachment_type": "signed_pdf",
    "storage_path": "contracts/e0000000-.../signed_pdf_20260408.pdf",
    "original_name": "合同签约件.pdf",
    "description": null,
    "size_bytes": 3145728,
    "uploaded_at": "2026-04-08T10:00:00Z",
    "uploaded_by": "f0000000-..."
  }
}
```

**错误码**

| 错误码 | HTTP | 说明 |
|--------|------|------|
| `CONTRACT_NOT_FOUND` | 404 | 合同不存在 |
| `FILE_TYPE_NOT_ALLOWED` | 415 | 非 PDF/图片类型 |
| `FILE_TOO_LARGE` | 413 | 超过限制 |

---

### 2.4 `POST /api/workorders/:id/photos` — 上传工单照片

**权限**: `workorder.write`

**Request** — `multipart/form-data`（支持多文件）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `files` | binary[] | 是 | 一次最多 9 张照片 |
| `photo_stage` | string | 是 | `report`（报修时）/ `completion`（完工时） |

**允许类型**: `.jpg`, `.jpeg`, `.png`

**存储路径**: `workorders/{work_order_id}/{photo_stage}_{index}.jpg`

**Response 201**

```json
{
  "data": {
    "work_order_id": "12000000-...",
    "photo_stage": "report",
    "photos": [
      { "index": 0, "storage_path": "workorders/12000000-.../report_0.jpg", "size_bytes": 524288 },
      { "index": 1, "storage_path": "workorders/12000000-.../report_1.jpg", "size_bytes": 612000 }
    ]
  }
}
```

**错误码**

| 错误码 | HTTP | 说明 |
|--------|------|------|
| `WORKORDER_NOT_FOUND` | 404 | 工单不存在 |
| `TOO_MANY_PHOTOS` | 400 | 单次上传超过 9 张 |
| `FILE_TYPE_NOT_ALLOWED` | 415 | 非图片类型 |

---

### 2.5 `POST /api/renovations/:id/photos` — 上传改造照片

**权限**: `assets.write`

**Request** — `multipart/form-data`（支持多文件）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `files` | binary[] | 是 | 最多 20 张 |
| `photo_stage` | string | 是 | `before`（改造前）/ `after`（改造后） |

**允许类型**: `.jpg`, `.jpeg`, `.png`

**存储路径**: `renovations/{record_id}/{photo_stage}_{index}.jpg`

**Response 201** — 结构同 2.4

---

### 2.6 `GET /api/files/{path}` — 文件代理访问

**权限**: 已登录

**路径参数**: `path` 为存储相对路径（如 `contracts/uuid/signed.pdf`）

**Response**: 文件二进制流 + 正确的 `Content-Type` 头

**安全校验**:
1. 路径规范化（防止 `../` 目录穿越）
2. RBAC 校验：合同附件需 `contract.read` 权限
3. 二房东用户只能访问自己绑定合同的文件

**错误码**

| 错误码 | HTTP | 说明 |
|--------|------|------|
| `FILE_NOT_FOUND` | 404 | 文件不存在 |
| `FILE_ACCESS_DENIED` | 403 | 无权访问该文件 |

---

## 三、文件类型白名单

| 端点 | 允许 MIME 类型 | 允许扩展名 |
|------|--------------|-----------|
| 通用上传 | `application/pdf`, `image/jpeg`, `image/png`, `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` | `.pdf`, `.jpg`, `.jpeg`, `.png`, `.xls`, `.xlsx` |
| CAD 上传 | `application/acad`, `application/octet-stream` | `.dwg` |
| 合同附件 | `application/pdf`, `image/jpeg`, `image/png` | `.pdf`, `.jpg`, `.jpeg`, `.png` |
| 工单照片 | `image/jpeg`, `image/png` | `.jpg`, `.jpeg`, `.png` |
| 改造照片 | `image/jpeg`, `image/png` | `.jpg`, `.jpeg`, `.png` |

---

## 四、后端实现要点

### 4.1 安全检查

```dart
/// backend/lib/middleware/upload_middleware.dart

// 1. 文件大小检查（在 Shelf middleware 层）
if (contentLength > maxUploadSize) {
  throw AppException('FILE_TOO_LARGE', '文件超过 ${maxSizeMB}MB 限制', 413);
}

// 2. MIME 类型校验（读取文件头魔术字节，不仅依赖 Content-Type header）
final detectedMime = lookupMimeType(filename, headerBytes: bytes.sublist(0, 12));
if (!allowedMimes.contains(detectedMime)) {
  throw AppException('FILE_TYPE_NOT_ALLOWED', '不支持的文件类型', 415);
}

// 3. 路径穿越防护
final normalized = path.normalize(requestedPath);
if (normalized.contains('..') || !normalized.startsWith(baseStoragePath)) {
  throw AppException('FILE_ACCESS_DENIED', '非法文件路径', 403);
}
```

### 4.2 文件存储 Service

```dart
/// backend/lib/services/file_storage_service.dart
class FileStorageService {
  final String _basePath; // 从 FILE_STORAGE_PATH 环境变量

  /// 保存文件，返回相对存储路径
  Future<String> save({
    required String category,   // 'contracts', 'workorders' 等
    required String resourceId, // UUID
    required String filename,   // 存储文件名
    required List<int> bytes,
  }) async {
    final dir = path.join(_basePath, category, resourceId);
    await Directory(dir).create(recursive: true);
    final filePath = path.join(dir, filename);
    await File(filePath).writeAsBytes(bytes);
    return '$category/$resourceId/$filename'; // 返回相对路径
  }
}
```
