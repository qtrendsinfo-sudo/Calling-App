import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseRealtimeService(supabase);
});

/// Reusable Realtime Channel Manager for Telora.
/// Handles ephemeral broadcast channels (signaling, typing), presence (online status),
/// and postgres change streams with deterministic disposal.
class SupabaseRealtimeService {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _activeChannels = {};

  SupabaseRealtimeService(this._supabase);

  /// Creates or retrieves a scoped broadcast channel (e.g., 'call:xyz' or 'chat:abc')
  RealtimeChannel getOrCreateChannel(String channelName) {
    if (_activeChannels.containsKey(channelName)) {
      return _activeChannels[channelName]!;
    }

    final channel = _supabase.channel(
      channelName,
      opts: const RealtimeChannelConfig(ack: true),
    );

    _activeChannels[channelName] = channel;
    return channel;
  }

  /// Sends an ephemeral broadcast payload (used for WebRTC signaling and typing indicators)
  Future<void> sendBroadcast({
    required String channelName,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final channel = getOrCreateChannel(channelName);
    try {
      await channel.sendBroadcastMessage(
        event: event,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[SupabaseRealtime] Broadcast error on $channelName: $e');
      rethrow;
    }
  }

  /// Registers user presence on a channel (e.g., user is online in app or in a conversation)
  Future<void> trackPresence({
    required String channelName,
    required Map<String, dynamic> presenceState,
  }) async {
    final channel = getOrCreateChannel(channelName);
    try {
      await channel.track(presenceState);
    } catch (e) {
      debugPrint('[SupabaseRealtime] Presence track error on $channelName: $e');
    }
  }

  /// Leaves presence tracking on a channel
  Future<void> untrackPresence(String channelName) async {
    if (!_activeChannels.containsKey(channelName)) return;
    try {
      await _activeChannels[channelName]!.untrack();
    } catch (e) {
      debugPrint('[SupabaseRealtime] Presence untrack error on $channelName: $e');
    }
  }

  /// Deterministically removes and unsubscribes a channel when leaving a screen
  Future<void> removeChannel(String channelName) async {
    if (!_activeChannels.containsKey(channelName)) return;
    try {
      final channel = _activeChannels.remove(channelName);
      if (channel != null) {
        await _supabase.removeChannel(channel);
        debugPrint('[SupabaseRealtime] Successfully removed channel: $channelName');
      }
    } catch (e) {
      debugPrint('[SupabaseRealtime] Error removing channel $channelName: $e');
    }
  }

  /// Cleanly removes all active channels (e.g. during user logout)
  Future<void> clearAllChannels() async {
    for (final channelName in _activeChannels.keys.toList()) {
      await removeChannel(channelName);
    }
    _activeChannels.clear();
  }
}
