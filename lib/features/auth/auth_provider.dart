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
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        final email = user?.email?.toLowerCase();
        if (user != null && (email == 'admin@aplibhaji.com' || email == 'ojasthamkes@gmail.com')) {
          state = AuthState(isAuthenticated: true, isLoading: false);
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

  Future<bool> login(String email, String password) async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user != null) {
        final loggedInEmail = res.user!.email?.trim().toLowerCase() ?? email.trim().toLowerCase();
        if (loggedInEmail == 'admin@aplibhaji.com' || loggedInEmail == 'ojasthamkes@gmail.com') {
          state = AuthState(isAuthenticated: true, isLoading: false);
          return true;
        } else {
          // If customer tries to log in to admin app
          await Supabase.instance.client.auth.signOut();
          state = AuthState(
            isAuthenticated: false,
            isLoading: false,
            error: 'Access denied: Unauthorized admin email ($loggedInEmail).',
          );
          return false;
        }
      }
      state = AuthState(isAuthenticated: false, isLoading: false, error: 'Authentication failed.');
      return false;
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString().replaceAll('AuthException: ', ''),
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
