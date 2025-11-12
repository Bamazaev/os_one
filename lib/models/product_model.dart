import 'package:equatable/equatable.dart';

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
    return ProductModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      barcode: map['barcode']?.toString() ?? '',
      categoryId: int.tryParse(map['categoryid']?.toString() ?? '0') ?? 0,
      name: map['name']?.toString() ?? '',
      imageBase64: map['image']?.toString(),
      description: map['description']?.toString(),
      stock: double.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      stockSold: double.tryParse(map['stock_furuhtashud']?.toString() ?? '0') ?? 0,
      purchasePrice: double.tryParse(map['narhiOmadagish']?.toString() ?? '0') ?? 0,
      salePrice: double.tryParse(map['narhifurush']?.toString() ?? '0') ?? 0,
      isFavorite: map['isFavorite']?.toString().toLowerCase() == 'true',
      position: int.tryParse(map['position']?.toString() ?? '0') ?? 0,
      expireAt: map['expireAt']?.toString(),
      piece: double.tryParse(map['piece']?.toString() ?? ''),
      unit: map['unit']?.toString(),
    );
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

