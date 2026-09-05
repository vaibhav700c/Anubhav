import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/detail_provider.dart';
import 'providers/history_provider.dart';
import 'providers/session_provider.dart';
import 'providers/twin_provider.dart';
import 'screens/home_shell.dart';
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
        theme: AppTheme.dark,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                  builder: (_) => const HomeShell());
            case '/detail':
              final sessionId = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => SessionDetailScreen(sessionId: sessionId),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                  builder: (_) => const HomeShell());
          }
        },
      ),
    );
  }
}
