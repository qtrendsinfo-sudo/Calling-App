import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';

final turnServiceProvider = Provider<TurnService>((ref) {
  return TurnServiceImpl();
});

abstract class TurnService {
  Future<List<Map<String, dynamic>>> getIceServers(EnvConfig config);
}

class TurnServiceImpl implements TurnService {
  @override
  Future<List<Map<String, dynamic>>> getIceServers(EnvConfig config) async {
    // Falls back to default STUN servers if Edge Function is not yet deployed
    final List<Map<String, dynamic>> iceServers = List.from(config.defaultIceServers);
    return iceServers;
  }
}
