import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';
import '../services/hive_service.dart';

/// BLoC барои идораи Splash Screen
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<SplashAnimationStarted>(_onSplashAnimationStarted);
    on<SplashAnimationCompleted>(_onSplashAnimationCompleted);
    on<SplashNavigateToHome>(_onSplashNavigateToHome);
  }

  /// Коркарди event-и оғоз
  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());
    
    // Каме интизор мешавем пеш аз оғози анимация
    await Future.delayed(const Duration(milliseconds: 300));
    
    add(const SplashAnimationStarted());
  }

  /// Коркарди event-и оғози анимация
  Future<void> _onSplashAnimationStarted(
    SplashAnimationStarted event,
    Emitter<SplashState> emit,
  ) async {
    // Анимацияро қадам ба қадам нишон медиҳем (2 секунд)
    for (int i = 0; i <= 100; i += 5) {
      emit(SplashAnimating(progress: i / 100));
      await Future.delayed(const Duration(milliseconds: 15)); // 2000ms / 100 * 5 = 15ms
    }
    
    add(const SplashAnimationCompleted());
  }

  /// Коркарди event-и анҷоми анимация
  Future<void> _onSplashAnimationCompleted(
    SplashAnimationCompleted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashCompleted());
    
    // 200 миллисекунд интизор мешавем пеш аз навигатсия
    await Future.delayed(const Duration(milliseconds: 200));
    
    add(const SplashNavigateToHome());
  }

  /// Коркарди event-и навигатсия
  Future<void> _onSplashNavigateToHome(
    SplashNavigateToHome event,
    Emitter<SplashState> emit,
  ) async {
    // Санҷиш - оё корбар логин шуда?
    print('🚀 SplashBloc: Санҷиши корбар...');
    final currentUser = HiveService.getCurrentUser();
    final isLoggedIn = currentUser != null;
    print('🔐 isLoggedIn: $isLoggedIn');
    
    emit(SplashNavigating(isLoggedIn: isLoggedIn));
  }
}

