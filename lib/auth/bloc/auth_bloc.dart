import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC барои идораи аутентификатсия
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  /// Санҷиши корбари ҷорӣ
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔍 AuthBloc: AuthCheckRequested...');
    emit(state.copyWithLoading());
    try {
      final user = await authRepository.getCurrentUser();
      print('👤 AuthBloc: user = ${user?.name}');
      if (user != null) {
        emit(state.copyWithUser(user));
        print('✅ AuthBloc: User set to state');
      } else {
        emit(state.copyWithLogout());
        print('❌ AuthBloc: No user, logout state');
      }
    } catch (e) {
      print('💥 AuthBloc: Error - $e');
      emit(state.copyWithError('Хатогӣ дар санҷиши корбар: ${e.toString()}'));
    }
  }

  /// Қайд шудан
  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWithLoading());
    try {
      final user = await authRepository.register(
        name: event.name,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
        password: event.password,
        photoBase64: event.photoBase64,
        headerBase64: event.headerBase64,
      );
      emit(state.copyWithUser(user));
    } catch (e) {
      emit(state.copyWithError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Ворид шудан
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWithLoading());
    try {
      final user = await authRepository.login(
        phone: event.phone,
        password: event.password,
      );
      emit(state.copyWithUser(user));
    } catch (e) {
      emit(state.copyWithError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Баромадан
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(state.copyWithLogout());
  }
}

