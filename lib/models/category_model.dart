import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final int id;
  final String name;
  final String? imageBase64;
  final int productCount;
  final int position;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageBase64,
    this.productCount = 0,
    this.position = 0,
  });

  // Factory from Google Sheets Map
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      name: map['name']?.toString() ?? '',
      imageBase64: map['image']?.toString(),
      productCount: int.tryParse(map['productCount']?.toString() ?? '0') ?? 0,
      position: int.tryParse(map['position']?.toString() ?? '0') ?? 0,
    );
  }

  // To Map for Google Sheets
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': imageBase64 ?? '',
      'productCount': productCount,
      'position': position,
    };
  }

  @override
  List<Object?> get props => [id, name, imageBase64, productCount, position];

  CategoryModel copyWith({
    int? id,
    String? name,
    String? imageBase64,
    int? productCount,
    int? position,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageBase64: imageBase64 ?? this.imageBase64,
      productCount: productCount ?? this.productCount,
      position: position ?? this.position,
    );
  }
}

