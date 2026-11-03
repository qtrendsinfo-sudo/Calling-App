import 'app_environment.dart';

/// Centralized configuration provider for Telora.
/// Values are injected via compile-time environment definitions or configuration files.
/// 
/// Example:
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=public-anon-key
class EnvConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String admobAppId;
  final String admobBannerId;
  final String admobInterstitialId;
  final List<Map<String, dynamic>> defaultIceServers;

  const EnvConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.admobAppId,
    required this.admobBannerId,
    required this.admobInterstitialId,
    required this.defaultIceServers,
  });

  /// Backward-compatible alias for Supabase publishable/anon key
  String get supabaseAnonKey => supabasePublishableKey;

  /// Helper to resolve publishable key from either SUPABASE_PUBLISHABLE_KEY or SUPABASE_ANON_KEY
  static String _resolvePublishableKey({String defaultValue = ''}) {
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (key.isNotEmpty) return key;
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  /// Factory constructor for development configuration with standard Google STUN
  /// and official Google AdMob test IDs for safe mobile development.
  factory EnvConfig.dev() {
    final key = _resolvePublishableKey(defaultValue: 'placeholder-anon-key-set-in-phase-3');
    return EnvConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://placeholder-project.supabase.co',
      ),
      supabasePublishableKey: key.isNotEmpty ? key : 'placeholder-anon-key-set-in-phase-3',
      // Official Google AdMob Test App ID & Ad Unit IDs for Android
      admobAppId: const String.fromEnvironment(
        'ADMOB_APP_ID',
        defaultValue: 'ca-app-pub-3940256099942544~3347511713',
      ),
      admobBannerId: const String.fromEnvironment(
        'ADMOB_BANNER_ID',
        defaultValue: 'ca-app-pub-3940256099942544/6300978111',
      ),
      admobInterstitialId: const String.fromEnvironment(
        'ADMOB_INTERSTITIAL_ID',
        defaultValue: 'ca-app-pub-3940256099942544/1033173712',
      ),
      defaultIceServers: const [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ],
        },
      ],
    );
  }

  /// Factory constructor for staging environment
  factory EnvConfig.staging() {
    return EnvConfig(
      environment: AppEnvironment.staging,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: _resolvePublishableKey(),
      admobAppId: const String.fromEnvironment('ADMOB_APP_ID'),
      admobBannerId: const String.fromEnvironment('ADMOB_BANNER_ID'),
      admobInterstitialId: const String.fromEnvironment('ADMOB_INTERSTITIAL_ID'),
      defaultIceServers: const [
        {
          'urls': ['stun:stun.l.google.com:19302'],
        },
      ],
    );
  }

  /// Factory constructor for production environment
  factory EnvConfig.prod() {
    return EnvConfig(
      environment: AppEnvironment.prod,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: _resolvePublishableKey(),
      admobAppId: const String.fromEnvironment('ADMOB_APP_ID'),
      admobBannerId: const String.fromEnvironment('ADMOB_BANNER_ID'),
      admobInterstitialId: const String.fromEnvironment('ADMOB_INTERSTITIAL_ID'),
      defaultIceServers: const [
        {
          'urls': ['stun:stun.l.google.com:19302'],
        },
      ],
    );
  }

  bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('placeholder-project') &&
      supabasePublishableKey.isNotEmpty &&
      !supabasePublishableKey.contains('placeholder');
}
