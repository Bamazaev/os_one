import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

// Load all products
class ProductsLoadRequested extends ProductEvent {
  final bool forceRefresh; // Force refresh from Google Sheets (skip cache)
  
  const ProductsLoadRequested({this.forceRefresh = false});
  
  @override
  List<Object?> get props => [forceRefresh];
}

// Load products by category
class ProductsLoadByCategory extends ProductEvent {
  final int categoryId;

  const ProductsLoadByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

// Add new product
class ProductAddRequested extends ProductEvent {
  final ProductModel product;

  const ProductAddRequested(this.product);

  @override
  List<Object?> get props => [product];
}

// Update product
class ProductUpdateRequested extends ProductEvent {
  final int id;
  final String barcode;
  final int categoryId;
  final String name;
  final String? imageBase64;
  final String? description;
  final double stock;
  final double purchasePrice;
  final double salePrice;
  final String? expireAt;
  final double? piece;
  final String? unit;

  const ProductUpdateRequested({
    required this.id,
    required this.barcode,
    required this.categoryId,
    required this.name,
    this.imageBase64,
    this.description,
    required this.stock,
    required this.purchasePrice,
    required this.salePrice,
    this.expireAt,
    this.piece,
    this.unit,
  });

  @override
  List<Object?> get props => [
        id,
        barcode,
        categoryId,
        name,
        imageBase64,
        description,
        stock,
        purchasePrice,
        salePrice,
        expireAt,
        piece,
        unit,
      ];
}

// Delete product
class ProductDeleteRequested extends ProductEvent {
  final int id;

  const ProductDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// Toggle view mode (grid/list)
class ProductViewModeToggled extends ProductEvent {
  const ProductViewModeToggled();
}

// Filter by expire date
class ProductFilterByExpireDate extends ProductEvent {
  final bool showExpired;

  const ProductFilterByExpireDate(this.showExpired);

  @override
  List<Object?> get props => [showExpired];
}

// Search products
class ProductSearchRequested extends ProductEvent {
  final String query;

  const ProductSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

