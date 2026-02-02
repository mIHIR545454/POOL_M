import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/history_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'TTC Pool Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin': (context) {
          if (authState.role == 'Admin') {
            return const AdminScreen();
          } else {
            return const DashboardScreen();
          }
        },
        '/history': (context) => const HistoryScreen(),
      },
      // Log interaction to reset inactivity timer
      builder: (context, child) {
        return GestureDetector(
          onTap: () => ref.read(authProvider.notifier).recordActivity(),
          onPanDown: (_) => ref.read(authProvider.notifier).recordActivity(),
          child: child,
        );
      },
    );
  }
}
