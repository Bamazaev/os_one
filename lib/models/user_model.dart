import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String lastName;
  
  @HiveField(3)
  final String email;
  
  @HiveField(4)
  final String phone;
  
  @HiveField(5)
  final String role; // 'admin' или 'user'
  
  @HiveField(6)
  final String? photoUrl; // Аватар (base64)
  
  @HiveField(7)
  final String? headerUrl; // Фони аватар (base64)

  const UserModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.photoUrl,
    this.headerUrl,
  });

  String get fullName => '$name $lastName';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      photoUrl: map['photoUrl']?.toString(),
      headerUrl: map['headerUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'photoUrl': photoUrl,
      'headerUrl': headerUrl,
    };
  }

  @override
  List<Object?> get props => [id, name, lastName, email, phone, role, photoUrl, headerUrl];
}

