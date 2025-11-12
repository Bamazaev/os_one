import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const String route = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+992');
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  
  // Для изображений
  Uint8List? _avatarBytes;
  Uint8List? _headerBytes;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _normalizePhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    return cleaned;
  }

  // Выбор аватара
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      Uint8List? bytes;
      
      // Барои Windows аз file_picker истифода мебарем
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) {
            final file = File(path);
            bytes = await file.readAsBytes();
          }
        }
      } else {
        // Для Android/iOS используем image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 70,
        );
        
        if (pickedFile != null) {
          bytes = await pickedFile.readAsBytes();
        }
      }
      
      if (bytes != null) {
        // Сжатие с меньшим размером и качеством для Google Sheets
        final image = img.decodeImage(bytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 150);
          final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 50));
          setState(() => _avatarBytes = compressed);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе фото: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Выбор фона
  Future<void> _pickHeader(ImageSource source) async {
    try {
      Uint8List? bytes;
      
      // Для Windows используем file_picker
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) {
            final file = File(path);
            bytes = await file.readAsBytes();
          }
        }
      } else {
        // Для Android/iOS используем image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 400,
          imageQuality: 70,
        );
        
        if (pickedFile != null) {
          bytes = await pickedFile.readAsBytes();
        }
      }
      
      if (bytes != null) {
        // Сжатие с меньшим размером и качеством для Google Sheets
        final image = img.decodeImage(bytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 600);
          final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 50));
          setState(() => _headerBytes = compressed);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе фона: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a4d3c),
              Color(0xFF0d6e58),
              Color(0xFF10b981),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
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
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
                                // Блоки Header и Avatar
                                SizedBox(
                                  height: 180,
                                  width: double.infinity,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Фон (Header)
                                      Container(
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          gradient: _headerBytes == null
                                              ? LinearGradient(
                                                  colors: [
                                                    const Color(0xFF34d399)
                                                        .withOpacity(0.3),
                                                    const Color(0xFF10b981)
                                                        .withOpacity(0.2),
                                                  ],
                                                )
                                              : null,
                                          image: _headerBytes != null
                                              ? DecorationImage(
                                                  image: MemoryImage(_headerBytes!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: _headerBytes == null
                                            ? Center(
                                                child: Icon(
                                                  Icons.landscape,
                                                  size: 40,
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                              )
                                            : null,
                                      ),
                                      // Кнопки Header
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Row(
                                          children: [
                                            _buildImageButton(
                                              icon: Icons.photo_library,
                                              onTap: () => _pickHeader(ImageSource.gallery),
                                              tooltip: 'Выбрать фон',
                                            ),
                                            if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) ...[
                                              const SizedBox(width: 5),
                                              _buildImageButton(
                                                icon: Icons.camera_alt,
                                                onTap: () => _pickHeader(ImageSource.camera),
                                                tooltip: 'Фон с камеры',
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Аватар
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF10b981),
                                                    width: 3,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF10b981)
                                                          .withOpacity(0.5),
                                                      blurRadius: 20,
                                                      spreadRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                                child: CircleAvatar(
                                                  radius: 50,
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.2),
                                                  backgroundImage: _avatarBytes != null
                                                      ? MemoryImage(_avatarBytes!)
                                                      : null,
                                                  child: _avatarBytes == null
                                                      ? const Icon(
                                                          Icons.person,
                                                          size: 50,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                              // Кнопки Avatar
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Row(
                                                  children: [
                                                    _buildImageButton(
                                                      icon: Icons.photo,
                                                      onTap: () =>
                                                          _pickAvatar(ImageSource.gallery),
                                                      tooltip: 'Выбрать фото',
                                                      small: true,
                                                    ),
                                                    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) ...[
                                                      const SizedBox(width: 5),
                                                      _buildImageButton(
                                                        icon: Icons.camera,
                                                        onTap: () =>
                                                            _pickAvatar(ImageSource.camera),
                                                        tooltip: 'Фото с камеры',
                                                        small: true,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Заголовок
                                const Text(
                                  'РЕГИСТРАЦИЯ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 32,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Создайте новый аккаунт',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Поля
                                _buildTextField(
                                  controller: _nameCtrl,
                                  hint: 'Имя',
                                  icon: Icons.person,
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _lastCtrl,
                                  hint: 'Фамилия',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _emailCtrl,
                                  hint: 'Email',
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Email обязателен';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Email некорректен';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _phoneCtrl,
                                  hint: '+992',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _passCtrl,
                                  hint: 'Пароль',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscure1,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure1
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure1 = !_obscure1),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _confirmCtrl,
                                  hint: 'Подтвердите пароль',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscure2,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure2
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure2 = !_obscure2),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Подтверждение пароля обязательно';
                                    }
                                    if (v != _passCtrl.text) {
                                      return 'Пароли не совпадают';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),

                                // Кнопка регистрации
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: state.loading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!.validate()) {
                                              context.read<AuthBloc>().add(
                                                    RegisterSubmitted(
                                                      name: _nameCtrl.text.trim(),
                                                      lastName: _lastCtrl.text.trim(),
                                                      email: _emailCtrl.text.trim(),
                                                      phone: _normalizePhone(
                                                          _phoneCtrl.text),
                                                      password: _passCtrl.text,
                                                      photoBase64: _avatarBytes != null
                                                          ? base64Encode(_avatarBytes!)
                                                          : null,
                                                      headerBase64: _headerBytes != null
                                                          ? base64Encode(_headerBytes!)
                                                          : null,
                                                    ),
                                                  );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34d399),
                                      foregroundColor: Colors.white,
                                      elevation: 10,
                                      shadowColor:
                                          const Color(0xFF10b981).withOpacity(0.5),
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
                                              Icon(Icons.person_add, size: 24),
                                              SizedBox(width: 10),
                                              Text(
                                                'ЗАРЕГИСТРИРОВАТЬСЯ',
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

                                // Ссылка на Login
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Уже есть аккаунт? ',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.8)),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const LoginScreen()),
                                        );
                                      },
                                      child: const Text(
                                        'Войдите',
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
        ),
      ),
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
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFF34d399)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
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
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Это поле обязательно' : null,
    );
  }

  // Кнопка выбора изображения
  Widget _buildImageButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool small = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF10b981),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: small ? 16 : 20),
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.all(small ? 6 : 8),
        constraints: BoxConstraints(
          minWidth: small ? 30 : 36,
          minHeight: small ? 30 : 36,
        ),
      ),
    );
  }
}

