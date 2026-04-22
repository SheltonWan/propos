/// 集成测试统一入口（可选）。
///
/// 将所有集成测试文件的 main() 汇聚为一次测试运行，
/// 适用于 CI 环境一键执行全部集成测试：
///
/// ```bash
/// flutter test integration_test/integration_test_main.dart \
///   --dart-define=API_BASE_URL=http://localhost:8080 \
///   --dart-define=IT_ADMIN_EMAIL=admin@propos.local \
///   --dart-define=IT_ADMIN_PASSWORD=Test1234! \
///   -d <device_or_simulator_id>
/// ```
///
/// 若只运行单个模块，可直接执行对应文件：
/// ```bash
/// flutter test integration_test/features/auth/auth_full_flow_test.dart \
///   --dart-define=API_BASE_URL=http://localhost:8080 \
///   -d <device_id>
/// ```
import 'package:integration_test/integration_test.dart';

import 'features/auth/auth_full_flow_test.dart' as auth_full_flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Auth 全链路（Repository 层 + Widget 层）
  auth_full_flow.main();
}
