abstract final class ApiConfig {
  ApiConfig._();

  /// Where the clinic's data lives. Never baked into a screen: point a build at
  /// another server with
  /// `flutter run --dart-define=BSP_API=http://10.0.2.2:8090` (10.0.2.2 is how
  /// the emulator reaches this Mac, where `./tool/dev_backend.sh start` runs).
  static const baseUrl = String.fromEnvironment(
    'BSP_API',
    defaultValue: 'https://app.api.sanjiwani.com.np',
  );
}
