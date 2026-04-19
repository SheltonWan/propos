import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration loaded from `.env` via [flutter_dotenv].
abstract final class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

  static bool get useMock =>
      dotenv.env['FLUTTER_USE_MOCK']?.toLowerCase() == 'true';
}
