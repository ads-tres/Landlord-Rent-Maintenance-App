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

  /// Firebase for push notifications, from the Firebase console's Android app settings.
  /// Push stays off when these are empty, so the app runs without a Firebase project.
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
