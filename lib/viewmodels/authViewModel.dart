import 'package:enmkit/models/users_model.dart';
import 'package:enmkit/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de l'authentification
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  /// Copie avec de nouveaux paramètres
  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// ViewModel
class AuthVM extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthVM(this._authRepository) : super(AuthState());

  /// Login
  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.login(phone, password);

      if (user != null) {
        state = state.copyWith(isLoading: false, user: user);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Numéro ou mot de passe incorrect',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Register
  Future<void> registerUser(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.registerUser(user);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Déconnexion
  void logout() {
    state = AuthState(); // Réinitialise l'état
  }
}

