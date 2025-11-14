import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_event.dart';
import '../../bloc/theme/theme_state.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+992');
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _normalizePhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    return cleaned;
  }

  @override
  void initState() {
    super.initState();

    // Контроллер fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Контроллер slide
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Запуск анимаций
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkMode ? null : Colors.white,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: themeState.isDarkMode
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0a4d3c),
                        Color(0xFF0d6e58),
                        Color(0xFF10b981),
                      ],
                    ),
                  )
                : const BoxDecoration(
                    color: Colors.white,
                  ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Кнопка переключения темы
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeState.isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: themeState.isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: themeState.isDarkMode
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                        onPressed: () {
                          context.read<ThemeBloc>().add(const ThemeToggled());
                        },
                        tooltip: themeState.isDarkMode ? 'Светлая тема' : 'Темная тема',
                      ),
                    ),
                  ),
                  // Основной контент
                  Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: themeState.isDarkMode ? null : Colors.white,
                      gradient: themeState.isDarkMode
                          ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: Border.all(
                        color: themeState.isDarkMode
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFF10b981).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeState.isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.error!),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          if (state.user != null) {
                            Navigator.pushReplacementNamed(
                              context,
                              HomeScreen.route,
                            );
                          }
                        },
                        builder: (context, state) {
                          return Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Большая иконка
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF34d399).withOpacity(0.3),
                                        const Color(0xFF10b981).withOpacity(0.2),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10b981).withOpacity(0.5),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 60,
                                    color: themeState.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF10b981),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Заголовок
                                Text(
                                  'ВХОД',
                                  style: TextStyle(
                                    color: themeState.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF10b981),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 36,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Войдите в свой аккаунт',
                                  style: TextStyle(
                                    color: themeState.isDarkMode
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Поле телефона
                                _buildTextField(
                                  controller: _phoneCtrl,
                                  hint: '+992',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Телефон обязателен' : null,
                                ),
                                const SizedBox(height: 20),

                                // Поле пароля
                                _buildTextField(
                                  controller: _passCtrl,
                                  hint: 'Пароль',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscure,
                                    suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off : Icons.visibility,
                                      color: themeState.isDarkMode
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Пароль обязателен' : null,
                                ),
                                const SizedBox(height: 30),

                                // Кнопка входа
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: state.loading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!.validate()) {
                                              context.read<AuthBloc>().add(
                                                    LoginSubmitted(
                                                      _normalizePhone(_phoneCtrl.text),
                                                      _passCtrl.text,
                                                    ),
                                                  );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34d399),
                                      foregroundColor: Colors.white,
                                      elevation: 10,
                                      shadowColor: const Color(0xFF10b981).withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: state.loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.login, size: 24),
                                              SizedBox(width: 10),
                                              Text(
                                                'ВОЙТИ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Ссылка на регистрацию
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Нет аккаунта? ',
                                      style: TextStyle(
                                        color: themeState.isDarkMode
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const RegisterScreen()),
                                        );
                                      },
                                      child: const Text(
                                        'Зарегистрируйтесь',
                                        style: TextStyle(
                                          color: Color(0xFF34d399),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final themeState = context.watch<ThemeBloc>().state;
    final isDark = themeState.isDarkMode;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.5)
              : Colors.grey[600],
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF34d399)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF34d399), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

