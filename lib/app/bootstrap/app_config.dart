/// Build-time configuration. Without Supabase values the app runs in demo
/// mode. Build the real-test APK with:
/// `flutter build apk --release --dart-define-from-file=config/supabase.json`
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  static bool get isSynced => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
