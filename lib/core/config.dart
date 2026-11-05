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

  /// Pilot feedback link (e.g. the pilot Telegram group). Settings hides the item when empty.
  /// `--dart-define=FEEDBACK_URL=https://t.me/+xxxx`
  static const feedbackUrl = String.fromEnvironment('FEEDBACK_URL');
}
