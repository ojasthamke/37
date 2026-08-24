import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notification Service
  try {
    await NotificationService.instance.init();
    debugPrint('NotificationService initialized successfully.');
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }
  
  // Try initializing Supabase
  try {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://xsqaxvbrjvhgemlfgoxn.supabase.co',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_7w2JdGBs0yI-P1pKfz7eOg_p2yV1qd_',
    );
    
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully.');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: ApliBhajiAdminApp(),
    ),
  );
}

class ApliBhajiAdminApp extends ConsumerWidget {
  const ApliBhajiAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'ApliBhaji Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Set light theme by default for store admin look
      home: authState.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : (authState.isAuthenticated
              ? const MainNavigationShell()
              : const LoginScreen()),
    );
  }
}
