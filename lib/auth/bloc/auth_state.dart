import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

/// State-ҳо барои аутентификатсия
class AuthState extends Equatable {
  final UserModel? user;
  final bool loading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.loading = false,
    this.error,
    this.isAuthenticated = false,
  });

  /// Ҳолати ибтидоӣ
  factory AuthState.initial() {
    return const AuthState();
  }

  /// Ҳолати loading
  AuthState copyWithLoading() {
    return AuthState(
      user: user,
      loading: true,
      error: null,
      isAuthenticated: isAuthenticated,
    );
  }

  /// Ҳолати муваффақ
  AuthState copyWithUser(UserModel user) {
    return AuthState(
      user: user,
      loading: false,
      error: null,
      isAuthenticated: true,
    );
  }

  /// Ҳолати хатогӣ
  AuthState copyWithError(String error) {
    return AuthState(
      user: user,
      loading: false,
      error: error,
      isAuthenticated: false,
    );
  }

  /// Ҳолати logout
  AuthState copyWithLogout() {
    return const AuthState(
      user: null,
      loading: false,
      error: null,
      isAuthenticated: false,
    );
  }

  @override
  List<Object?> get props => [user, loading, error, isAuthenticated];
}

