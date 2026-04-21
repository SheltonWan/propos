import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

/// BLoC/Cubit 全局观察器。
///
/// 将所有 BLoC 的生命周期事件（创建、状态变更、错误、关闭）
/// 统一接入 [AppLogger]，无需修改任何业务 Cubit 代码（零侵入）。
///
/// 日志级别约定：
/// - onCreate / onChange / onClose → debug（仅 debug/profile build 输出）
/// - onError → error（所有构建模式均记录）
///
/// 注册方式（在 main() 中 configureDependencies() 之后）：
/// ```dart
/// Bloc.observer = AppBlocObserver(getIt<AppLogger>());
/// ```
class AppBlocObserver extends BlocObserver {
  final AppLogger _logger;

  const AppBlocObserver(this._logger);

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _logger.debug('[BLoC] onCreate: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _logger.debug(
      '[BLoC] onChange: ${bloc.runtimeType} '
      '${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
    );
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.debug('[BLoC] onEvent: ${bloc.runtimeType} ← ${event.runtimeType}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error('[BLoC] onError: ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _logger.debug('[BLoC] onClose: ${bloc.runtimeType}');
  }
}
