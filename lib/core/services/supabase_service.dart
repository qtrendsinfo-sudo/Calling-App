import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../errors/app_exception.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.instance.client;
});

final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return SupabaseService.instance.auth;
});

final supabaseStorageProvider = Provider<SupabaseStorageClient>((ref) {
  return SupabaseService.instance.storage;
});

final supabaseRealtimeProvider = Provider<RealtimeClient>((ref) {
  return SupabaseService.instance.realtime;
});

/// Centralized Supabase Lifecycle & Service Manager.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Supabase client once using the provided environment configuration.
  Future<void> initialize(EnvConfig config) async {
    if (_isInitialized) {
      debugPrint('[SupabaseService] Already initialized.');
      return;
    }

    if (!config.isConfigured) {
      debugPrint('[SupabaseService] Notice: Placeholder or unconfigured Supabase credentials. Standby mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 20,
        ),
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Connected successfully to ${config.supabaseUrl}');
    } catch (e) {
      debugPrint('[SupabaseService] Notice: Offline / Standby mode activated: $e');
      _isInitialized = false;
    }
  }

  /// Primary client instance
  SupabaseClient get client {
    if (!_isInitialized) {
      // In development or when unconfigured, return Supabase.instance.client safely if available
      try {
        return Supabase.instance.client;
      } catch (_) {
        throw const DatabaseException(
          message: 'Supabase is not initialized. Please ensure valid credentials in Phase 3.',
        );
      }
    }
    return Supabase.instance.client;
  }

  /// Supabase Auth Client
  GoTrueClient get auth => client.auth;

  /// Supabase Storage Client
  SupabaseStorageClient get storage => client.storage;

  /// Supabase Realtime Client
  RealtimeClient get realtime => client.realtime;

  /// Reconnects Realtime websocket upon network restoration
  void handleNetworkReconnect() {
    if (!_isInitialized) return;
    try {
      client.realtime.connect();
      debugPrint('[SupabaseService] Realtime websocket reconnected after network restore.');
    } catch (e) {
      debugPrint('[SupabaseService] Error reconnecting Realtime: $e');
    }
  }

  /// Disconnects Realtime websocket when internet is lost to prevent futile retry loops
  void handleNetworkDisconnect() {
    if (!_isInitialized) return;
    try {
      client.realtime.disconnect();
      debugPrint('[SupabaseService] Realtime websocket paused during network outage.');
    } catch (e) {
      debugPrint('[SupabaseService] Error pausing Realtime: $e');
    }
  }
}
