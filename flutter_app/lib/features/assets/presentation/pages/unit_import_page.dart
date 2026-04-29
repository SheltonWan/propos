import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/custom_colors.dart';
import '../bloc/unit_import_cubit.dart';

/// 房源 Excel 批量导入页。
///
/// 功能：
/// 1. 显示模板说明（字段要求）
/// 2. 选择本地 `.xlsx` 文件（通过 [FilePicker]）
/// 3. 上传并展示导入结果（成功/失败行统计 + 失败详情）
class UnitImportPage extends StatefulWidget {
  const UnitImportPage({super.key});

  @override
  State<UnitImportPage> createState() => _UnitImportPageState();
}

class _UnitImportPageState extends State<UnitImportPage> {
  /// 已选文件名（仅用于展示，上传路径由 [_selectedFilePath] 持有）。
  String? _selectedFileName;
  String? _selectedFilePath;

  /// 弹出 FilePicker 选择 xlsx 文件。
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    setState(() {
      _selectedFilePath = file.path;
      _selectedFileName = file.name;
    });
  }

  void _upload() {
    if (_selectedFilePath == null || _selectedFileName == null) return;
    context.read<UnitImportCubit>().upload(
          filePath: _selectedFilePath!,
          fileName: _selectedFileName!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('批量导入房源'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<UnitImportCubit, UnitImportState>(
        listener: (context, state) {
          if (state is UnitImportStateSuccess) {
            // 导入完成后不自动关闭，留在页面展示结果
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TemplateHint(),
                const SizedBox(height: 24),
                _FilePickerCard(
                  fileName: _selectedFileName,
                  onPick: state is UnitImportStateUploading ? null : _pickFile,
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: (_selectedFilePath != null &&
                          state is! UnitImportStateUploading)
                      ? _upload
                      : null,
                  child: state is UnitImportStateUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(color: Colors.white),
                            SizedBox(width: 8),
                            Text('正在上传…'),
                          ],
                        )
                      : const Text('开始导入'),
                ),
                const SizedBox(height: 24),
                // 结果区域
                switch (state) {
                  UnitImportStateSuccess(:final successCount, :final failedCount, :final errors) =>
                    _ImportResultCard(
                      successCount: successCount,
                      failedCount: failedCount,
                      errors: errors,
                      onReset: () {
                        setState(() {
                          _selectedFilePath = null;
                          _selectedFileName = null;
                        });
                        context.read<UnitImportCubit>().reset();
                      },
                    ),
                  UnitImportStateError(:final message) => _ErrorCard(message: message),
                  _ => const SizedBox.shrink(),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Excel 模板字段说明卡片。
class _TemplateHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.doc_text,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Excel 模板要求',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• 支持 .xlsx / .xls 格式\n'
            '• 必填列：楼栋编号、楼层编号、房源号、业态\n'
            '• 可选列：建筑面积、使用面积、装修状态、参考租金\n'
            '• 业态值：office / retail / apartment',
            style: TextStyle(fontSize: 13, height: 1.7),
          ),
        ],
      ),
    );
  }
}

/// 文件选择卡片。
class _FilePickerCard extends StatelessWidget {
  final String? fileName;
  final VoidCallback? onPick;

  const _FilePickerCard({this.fileName, this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fileName != null ? scheme.primary : scheme.outlineVariant,
            width: fileName != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              fileName != null
                  ? CupertinoIcons.doc_fill
                  : CupertinoIcons.cloud_upload,
              color: fileName != null ? scheme.primary : scheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? '点击选择 Excel 文件',
                    style: TextStyle(
                      fontWeight: fileName != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: fileName != null
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (fileName == null)
                    Text(
                      '支持 .xlsx / .xls',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (fileName != null)
              Icon(CupertinoIcons.checkmark_circle_fill,
                  color: scheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// 导入成功结果卡片。
class _ImportResultCard extends StatelessWidget {
  final int successCount;
  final int failedCount;
  final List<String> errors;
  final VoidCallback onReset;

  const _ImportResultCard({
    required this.successCount,
    required this.failedCount,
    required this.errors,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('导入完成',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.success)),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(label: '成功', value: successCount, color: colors.success),
              const SizedBox(width: 12),
              if (failedCount > 0)
                _StatChip(label: '失败', value: failedCount, color: colors.danger),
            ],
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('失败行详情',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            ...errors.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(CupertinoIcons.exclamationmark_circle,
                          size: 14, color: colors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(e,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onReset,
              child: const Text('重新导入'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 导入失败错误卡片。
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle_fill,
              color: colors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: colors.danger))),
        ],
      ),
    );
  }
}

/// 统计小圆片（成功数 / 失败数）。
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
