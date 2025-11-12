import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/splash_bloc.dart';
import 'bloc/splash_event.dart';
import 'bloc/splash_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'dart:math' as math;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(const SplashStarted()),
      child: const SplashView(),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    _fadeController.forward();
    _scaleController.forward();
    _rotateController.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        _waveController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final logoSize = isDesktop ? 280.0 : 180.0;
    final padding1 = isDesktop ? 70.0 : 50.0;
    final padding2 = isDesktop ? 45.0 : 30.0;
    
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigating) {
          print('📍 SplashNavigating: isLoggedIn = ${state.isLoggedIn}');
          if (state.isLoggedIn) {
            print('➡️ Navigating to HomeScreen');
            Navigator.of(context).pushReplacementNamed(HomeScreen.route);
          } else {
            print('➡️ Navigating to LoginScreen');
            Navigator.of(context).pushReplacementNamed(LoginScreen.route);
          }
        }
      },
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0a4d3c),
                Color(0xFF0d6e58),
                Color(0xFF10b981),
                Color(0xFF34d399),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(40, (index) {
                return _buildParticle(index);
              }),
              
              ...List.generate(5, (index) {
                return _buildBackgroundCircle(index);
              }),
              
              ...List.generate(4, (index) {
                return _buildWaveCircle(index);
              }),
              
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _fadeController,
                    _scaleController,
                    _rotateController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value * _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value * math.pi,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Лого бо эффектҳои 3D
                              AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) {
                                  return Transform(
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateX(0.1 * math.sin(_glowAnimation.value * math.pi))
                                      ..rotateY(0.1 * math.cos(_glowAnimation.value * math.pi)),
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: EdgeInsets.all(padding1),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Color(0xFF6ee7b7).withOpacity(0.4 * _glowAnimation.value),
                                            Color(0xFF34d399).withOpacity(0.3 * _glowAnimation.value),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10b981).withOpacity(0.8),
                                            blurRadius: (isDesktop ? 150 : 100) * _glowAnimation.value,
                                            spreadRadius: (isDesktop ? 40 : 25) * _glowAnimation.value,
                                          ),
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.6),
                                            blurRadius: (isDesktop ? 200 : 140) * _glowAnimation.value,
                                            spreadRadius: (isDesktop ? 60 : 40) * _glowAnimation.value,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF6ee7b7).withOpacity(0.5),
                                            blurRadius: (isDesktop ? 250 : 180) * _glowAnimation.value,
                                            spreadRadius: (isDesktop ? 80 : 55) * _glowAnimation.value,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(padding2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white10,
                                              Colors.transparent,
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.4 + (0.4 * _glowAnimation.value)),
                                            width: (isDesktop ? 4 : 3) + (2 * _glowAnimation.value),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.4),
                                              blurRadius: (isDesktop ? 50 : 35) * _glowAnimation.value,
                                              spreadRadius: (isDesktop ? 15 : 10) * _glowAnimation.value,
                                            ),
                                          ],
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/logo/logo_white no back.svg',
                                          width: logoSize,
                                          height: logoSize,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.white,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCircle(int index) {
    final size = 400.0 + (index * 150);
    final delay = index * 0.2;
    
    return Center(
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          final adjustedValue = (_waveAnimation.value + delay) % 1.0;
          return Transform.scale(
            scale: 0.3 + (adjustedValue * 1.2),
            child: Opacity(
              opacity: (1 - adjustedValue) * 0.15,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF6ee7b7),
                      Color(0xFF34d399),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveCircle(int index) {
    final size = 300.0 + (index * 100);
    
    return Center(
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          final adjustedValue = (_waveAnimation.value + (index * 0.25)) % 1.0;
          return Transform.scale(
            scale: 0.5 + (adjustedValue * 1.8),
            child: Opacity(
              opacity: (1 - adjustedValue) * 0.4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6ee7b7).withOpacity(0.6),
                    width: 3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final size = math.Random(index).nextDouble() * 6 + 3;
    final top = math.Random(index * 10).nextDouble() * 800;
    final left = math.Random(index * 20).nextDouble() * 600;
    final duration = math.Random(index * 30).nextInt(3000) + 2000;
    
    final colors = [
      const Color(0xFF10b981),
      const Color(0xFF34d399),
      Colors.white,
      const Color(0xFF6ee7b7),
      const Color(0xFF059669),
    ];
    final particleColor = colors[index % colors.length];
    
    return Positioned(
      top: top,
      left: left,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: duration),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: (math.sin(value * math.pi * 2) + 1) / 2 * 0.8,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    particleColor.withOpacity(0.9),
                    particleColor.withOpacity(0.3),
                    particleColor.withOpacity(0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: particleColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          );
        },
        onEnd: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}
