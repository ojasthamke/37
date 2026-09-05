import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isAuthenticated;
  final String? error;
  final bool isLoading;

  AuthState({required this.isAuthenticated, this.error, this.isLoading = false});

  AuthState copyWith({bool? isAuthenticated, String? error, bool? isLoading}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isAuthenticated: false, isLoading: true)) {
    _initAuth();
  }

  static const Set<String> _allowedAdminEmails = {
    'admin@aplibhaji.com',
    'ojast009@aplibhaji.com',
    'ojasthamkes@gmail.com',
    '8605780069@aplibhaji.com',
    '90211070098@aplibhaji.com',
  };

  Future<void> _initAuth() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final isAdmin = await _verifyAdminUser(user);
        state = AuthState(isAuthenticated: isAdmin, isLoading: false);
      } else {
        state = AuthState(isAuthenticated: false, isLoading: false);
      }

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final user = data.session?.user;
        if (user != null) {
          final isAdmin = await _verifyAdminUser(user);
          state = AuthState(isAuthenticated: isAdmin, isLoading: false);
        } else {
          state = AuthState(isAuthenticated: false, isLoading: false);
        }
      }, onError: (_) {
        state = AuthState(isAuthenticated: false, isLoading: false);
      });
    } catch (_) {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> _verifyAdminUser(User user) async {
    final email = user.email?.trim().toLowerCase() ?? '';
    if (_allowedAdminEmails.contains(email)) {
      return true;
    }

    try {
      final res = await Supabase.instance.client
          .from('admin_roles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();
      if (res != null && (res['role'] == 'admin' || res['role'] == 'superadmin')) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<bool> login(String inputIdentifier, String password) async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    try {
      var email = inputIdentifier.trim().toLowerCase();
      if (!email.contains('@')) {
        email = '$email@aplibhaji.com';
      }

      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final isAdmin = await _verifyAdminUser(res.user!);
        if (isAdmin) {
          state = AuthState(isAuthenticated: true, isLoading: false);
          return true;
        } else {
          await Supabase.instance.client.auth.signOut();
          state = AuthState(
            isAuthenticated: false,
            isLoading: false,
            error: 'Access denied: User ($email) does not have admin privileges.',
          );
          return false;
        }
      }
      state = AuthState(isAuthenticated: false, isLoading: false, error: 'Authentication failed. Please check credentials.');
      return false;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('AuthException: ', '');
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
