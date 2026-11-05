/// Build-time configuration.
///
/// Override with `--dart-define=API_BASE_URL=https://api.example.et/api/v1`.
/// The default points at a Laravel dev server reachable from the Android emulator.
class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
