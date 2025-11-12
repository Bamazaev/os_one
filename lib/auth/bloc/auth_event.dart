import 'package:equatable/equatable.dart';

/// Event-ҳо барои аутентификатсия
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event барои санҷиши корбари ҷорӣ
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event барои қайд шудан
class RegisterSubmitted extends AuthEvent {
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String? photoBase64;
  final String? headerBase64;

  const RegisterSubmitted({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    this.photoBase64,
    this.headerBase64,
  });

  @override
  List<Object?> get props => [name, lastName, email, phone, password, photoBase64, headerBase64];
}

/// Event барои ворид шудан
class LoginSubmitted extends AuthEvent {
  final String phone;
  final String password;

  const LoginSubmitted(this.phone, this.password);

  @override
  List<Object?> get props => [phone, password];
}

/// Event барои баромадан
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

