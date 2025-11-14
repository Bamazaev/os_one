import 'package:equatable/equatable.dart';
import '../utils/base64_helper.dart';

class ProductModel extends Equatable {
  final int id;
  final String barcode;
  final int categoryId;
  final String name;
  final String? imageBase64;
  final String? description;
  final double stock;
  final double stockSold; // stock furuhtashud
  final double purchasePrice; // narhiOmadagish
  final double salePrice; // narhifurush
  final bool isFavorite;
  final int position;
  final String? expireAt; // Срок годности
  final double? piece; // Қисм/Донагӣ
  final String? unit; // Воҳиди андоза (кг, шт, л)

  const ProductModel({
    required this.id,
    required this.barcode,
    required this.categoryId,
    required this.name,
    this.imageBase64,
    this.description,
    required this.stock,
    this.stockSold = 0,
    required this.purchasePrice,
    required this.salePrice,
    this.isFavorite = false,
    required this.position,
    this.expireAt,
    this.piece,
    this.unit,
  });

  // From Map (Google Sheets)
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    // Find categoryId field (case-insensitive)
    int categoryId = 0;
    for (var key in map.keys) {
      if (key.toLowerCase() == 'categoryid' || key.toLowerCase() == 'category_id') {
        final value = map[key];
        if (value != null) {
          categoryId = int.tryParse(value.toString().trim()) ?? 0;
        }
        break;
      }
    }
    // Fallback to direct access if not found
    if (categoryId == 0) {
      final catValue = map['categoryid'] ?? map['categoryId'];
      if (catValue != null) {
        categoryId = int.tryParse(catValue.toString().trim()) ?? 0;
      }
    }
    
    // Parse ID - handle large numbers by taking modulo if needed
    final idValue = map['id']?.toString().trim() ?? '0';
    int productId = int.tryParse(idValue) ?? 0;
    // If ID is too large, use modulo to keep it in safe range
    if (productId > 2147483647) {
      productId = productId % 2147483647;
    }
    
    // Очищаем base64 от префикса data URI если он есть
    final rawImage = map['image']?.toString();
    final cleanImage = rawImage != null && rawImage.isNotEmpty 
        ? cleanBase64String(rawImage) 
        : null;
    
    return ProductModel(
      id: productId,
      barcode: (map['barcode']?.toString() ?? '').trim(),
      categoryId: categoryId,
      name: (map['name']?.toString() ?? '').trim(),
      imageBase64: cleanImage,
      description: map['description']?.toString() != null ? map['description'].toString().trim() : null,
      stock: double.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      stockSold: double.tryParse(map['stock_furuhtashud']?.toString() ?? '0') ?? 0,
      purchasePrice: double.tryParse(map['narhiOmadagish']?.toString() ?? '0') ?? 0,
      salePrice: double.tryParse(map['narhifurush']?.toString() ?? '0') ?? 0,
      isFavorite: (map['isFavorite']?.toString() ?? '').toLowerCase().trim() == 'true',
      position: int.tryParse(map['position']?.toString() ?? '0') ?? 0,
      expireAt: map['expireAt']?.toString() != null ? map['expireAt'].toString().trim() : null,
      piece: double.tryParse(map['piece']?.toString() ?? ''),
      unit: _normalizeUnit(map['unit']?.toString()),
    );
  }

  // Нормализация единиц измерения - всегда в нижнем регистре
  static String? _normalizeUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) {
      return null;
    }
    
    final trimmed = unit.trim();
    final normalized = trimmed.toUpperCase();
    
    // Нормализация различных вариантов к нижнему регистру
    if (normalized == 'KG' || normalized == 'КГ' || normalized == 'КИЛОГРАММ') {
      return 'кг';
    } else if (normalized == 'L' || normalized == 'Л' || normalized == 'ЛИТР' || normalized == 'LITRE' || normalized == 'LITER') {
      return 'л';
    } else if (normalized == 'M' || normalized == 'М' || normalized == 'МЕТР' || normalized == 'METER' || normalized == 'METRE') {
      return 'м';
    } else if (normalized == 'PCS' || normalized == 'PCE' || normalized == 'ШТ' || normalized == 'ШТУКА' || normalized == 'PIECE' || normalized == 'PCS.') {
      return 'шт';
    }
    
    // Если единица уже в правильном формате (кг, л, м, шт), возвращаем в нижнем регистре
    final lower = trimmed.toLowerCase();
    if (lower == 'кг' || lower == 'л' || lower == 'м' || lower == 'шт') {
      return lower;
    }
    
    // Если не распознано, возвращаем в нижнем регистре как есть
    return lower;
  }

  // To Map (Google Sheets)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'categoryid': categoryId,
      'name': name,
      'image': imageBase64 ?? '',
      'description': description ?? '',
      'stock': stock,
      'stock_furuhtashud': stockSold,
      'narhiOmadagish': purchasePrice,
      'narhifurush': salePrice,
      'isFavorite': isFavorite,
      'position': position,
      'expireAt': expireAt ?? '',
      'piece': piece ?? '',
      'unit': unit ?? '',
    };
  }

  ProductModel copyWith({
    int? id,
    String? barcode,
    int? categoryId,
    String? name,
    String? imageBase64,
    String? description,
    double? stock,
    double? stockSold,
    double? purchasePrice,
    double? salePrice,
    bool? isFavorite,
    int? position,
    String? expireAt,
    double? piece,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      imageBase64: imageBase64 ?? this.imageBase64,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      stockSold: stockSold ?? this.stockSold,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      isFavorite: isFavorite ?? this.isFavorite,
      position: position ?? this.position,
      expireAt: expireAt ?? this.expireAt,
      piece: piece ?? this.piece,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        barcode,
        categoryId,
        name,
        imageBase64,
        description,
        stock,
        stockSold,
        purchasePrice,
        salePrice,
        isFavorite,
        position,
        expireAt,
        piece,
        unit,
      ];
}

