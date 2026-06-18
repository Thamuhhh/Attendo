import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool initialized;

  const AuthState({this.isLoggedIn = false, this.initialized = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await AuthService.init();
    state = AuthState(isLoggedIn: AuthService.isLoggedIn, initialized: true);
  }

  Future<void> login(String email, String password) async {
    await AuthService.login(email, password);
    state = AuthState(isLoggedIn: true, initialized: true);
  }

  Future<void> register(String name, String email, String phone, String password) async {
    await AuthService.register(name, email, phone, password);
    state = AuthState(isLoggedIn: true, initialized: true);
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = AuthState(isLoggedIn: false, initialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
