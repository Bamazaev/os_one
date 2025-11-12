import 'package:equatable/equatable.dart';

/// State-ҳо барои Splash Screen
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

/// Ҳолати ибтидоӣ
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Ҳолати Loading - анимация дар ҳоли иҷро
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// Ҳолати анимацияи дар ҳоли кор
class SplashAnimating extends SplashState {
  final double progress; // 0.0 то 1.0

  const SplashAnimating({this.progress = 0.0});

  @override
  List<Object> get props => [progress];
}

/// Ҳолати тамом - омодаи гузаштан ба саҳифаи асосӣ
class SplashCompleted extends SplashState {
  const SplashCompleted();
}

/// Ҳолати Navigate - гузаштан ба саҳифаи асосӣ
class SplashNavigating extends SplashState {
  final bool isLoggedIn; // Оё корбар логин шуда?
  
  const SplashNavigating({this.isLoggedIn = false});
  
  @override
  List<Object> get props => [isLoggedIn];
}

