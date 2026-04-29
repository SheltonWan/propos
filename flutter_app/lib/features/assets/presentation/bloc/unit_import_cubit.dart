import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/repositories/assets_repository.dart';

part 'unit_import_cubit.freezed.dart';

/// 房源 Excel 批量导入状态（四态）。
@freezed
sealed class UnitImportState with _$UnitImportState {
  /// 初始状态（尚未选择文件）。
  const factory UnitImportState.initial() = UnitImportStateInitial;

  /// 正在上传/解析中。
  const factory UnitImportState.uploading() = UnitImportStateUploading;

  /// 上传完成，返回成功数 / 失败数 / 失败行详情。
  const factory UnitImportState.success({
    required int successCount,
    required int failedCount,
    required List<String> errors,
  }) = UnitImportStateSuccess;

  /// 上传失败（网络或服务端错误）。
  const factory UnitImportState.error(String message) = UnitImportStateError;
}

/// 控制 Excel 批量导入房源的上传流程。
///
/// 通过 [AssetsRepository.uploadUnits] 发送 multipart 请求，
/// 后端解析 Excel 后返回成功条数与失败行描述。
class UnitImportCubit extends Cubit<UnitImportState> {
  final AssetsRepository _repository;

  UnitImportCubit(this._repository) : super(const UnitImportState.initial());

  /// 上传选定的 Excel 文件。
  ///
  /// [filePath] 为本地文件路径，[fileName] 用于 multipart Content-Disposition。
  Future<void> upload({
    required String filePath,
    required String fileName,
  }) async {
    emit(const UnitImportState.uploading());
    try {
      final result = await _repository.uploadUnits(filePath, fileName);
      emit(UnitImportState.success(
        successCount: result.success,
        failedCount: result.failed,
        errors: result.errors,
      ));
    } catch (e) {
      emit(UnitImportState.error(
        e is ApiException ? e.message : '上传失败，请稍后重试',
      ));
    }
  }

  /// 重置为初始状态（重新选文件）。
  void reset() => emit(const UnitImportState.initial());
}
