import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String? id;
  final String? role;
  final String? name;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.id,
    this.role,
    this.name,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? id,
    String? role,
    String? name,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  Timer? _inactivityTimer;
  static const Duration inactivityLimit = Duration(minutes: 30);

  AuthNotifier() : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ApiService.getToken();
    if (token != null) {
      final role = await ApiService.getRole();
      final userId = await ApiService.getUserId();
      state = state.copyWith(isAuthenticated: true, role: role, id: userId);
      _resetInactivityTimer();
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ApiService.login(identifier, password);
    
    if (result['success']) {
      state = state.copyWith(
        isAuthenticated: true,
        id: result['user']['id'],
        role: result['user']['role'],
        name: result['user']['username'],
        isLoading: false,
      );
      _resetInactivityTimer();
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result['message']);
      return false;
    }
  }

  void logout() {
    ApiService.logout();
    _inactivityTimer?.cancel();
    state = AuthState();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityLimit, () {
      logout();
    });
  }

  // Call this on any user interaction
  void recordActivity() {
    if (state.isAuthenticated) {
      _resetInactivityTimer();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
