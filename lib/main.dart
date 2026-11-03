import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/env_config.dart';
import 'core/services/ad_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration (Development defaults with test AdMob IDs & STUN)
  final envConfig = EnvConfig.dev();

  // Initialize Supabase infrastructure services safely before application render
  try {
    await SupabaseService.instance.initialize(envConfig);
  } catch (e) {
    debugPrint('[Main] Supabase initialization deferral: $e');
  }

  final container = ProviderContainer();
  try {
    await container.read(adServiceProvider).initialize(envConfig);
  } catch (e) {
    debugPrint('[Main] AdMob initialization deferral: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TeloraApp(),
    ),
  );
}
