import 'package:equatable/equatable.dart';

/// Event-ҳо барои Splash Screen
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object> get props => [];
}

/// Event барои оғози splash screen
class SplashStarted extends SplashEvent {
  const SplashStarted();
}

/// Event барои анимацияи оғозёфта
class SplashAnimationStarted extends SplashEvent {
  const SplashAnimationStarted();
}

/// Event барои анимацияи тамомшуда
class SplashAnimationCompleted extends SplashEvent {
  const SplashAnimationCompleted();
}

/// Event барои гузаштан ба саҳифаи асосӣ
class SplashNavigateToHome extends SplashEvent {
  const SplashNavigateToHome();
}

