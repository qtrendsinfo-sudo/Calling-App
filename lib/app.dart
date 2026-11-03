import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_service.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common_widgets/offline_banner_widget.dart';

/// Root Application Widget for Telora.
class TeloraApp extends ConsumerWidget {
  const TeloraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactively listen to connectivity changes to sync Realtime websocket state
    ref.listen<AsyncValue<bool>>(isConnectedStreamProvider, (previous, next) {
      final isOnline = next.asData?.value ?? true;
      if (isOnline) {
        SupabaseService.instance.handleNetworkReconnect();
      } else {
        SupabaseService.instance.handleNetworkDisconnect();
      }
    });

    final connectivityAsync = ref.watch(isConnectedStreamProvider);
    final isOnline = connectivityAsync.asData?.value ?? true;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('ar', 'AE'), // Arabic (RTL support)
      ],
      builder: (context, child) {
        return Scaffold(
          body: Column(
            children: [
              if (!isOnline)
                OfflineBannerWidget(
                  onRetry: () => ref.refresh(isConnectedStreamProvider),
                ),
              Expanded(
                child: child ?? const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
