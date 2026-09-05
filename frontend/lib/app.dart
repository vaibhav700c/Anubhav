import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/detail_provider.dart';
import 'providers/history_provider.dart';
import 'providers/session_provider.dart';
import 'providers/twin_provider.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pre_session_setup_screen.dart';
import 'screens/vr_handoff_screen.dart';
import 'screens/live_dashboard_screen.dart';
import 'screens/session_detail_screen.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'theme/app_theme.dart';

class AnubhavApp extends StatelessWidget {
  const AnubhavApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final cacheService = CacheService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(apiService, cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => DetailProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(apiService, cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => TwinProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Anubhav',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeShell(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/setup': (_) => const PreSessionSetupScreen(),
          '/vr-handoff': (_) => const VrHandoffScreen(),
          '/live': (_) => const LiveDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/detail') {
            final sessionId = settings.arguments as String? ?? 's001';
            return MaterialPageRoute(
              builder: (_) => SessionDetailScreen(sessionId: sessionId),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}
