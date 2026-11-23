/// Supabase project settings, read at build time.
///
/// Values come from `--dart-define` so no keys are committed:
///
/// ```sh
/// flutter run -d linux \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// The anon key is designed to be public; Row Level Security is what protects
/// data. It still should not be committed, because it identifies the project.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both values were supplied to the build.
  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static const SupabaseConfig current = SupabaseConfig(
    url: _url,
    anonKey: _anonKey,
  );
}
