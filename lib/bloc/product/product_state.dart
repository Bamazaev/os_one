import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

enum ProductViewMode { grid, list }

class ProductState extends Equatable {
  final List<ProductModel> products;
  final int? selectedCategoryId;
  final bool isLoading;
  final String? error;
  final ProductViewMode viewMode;
  final bool showExpired;

  const ProductState({
    this.products = const [],
    this.selectedCategoryId,
    this.isLoading = false,
    this.error,
    this.viewMode = ProductViewMode.grid,
    this.showExpired = false,
  });

  // Initial state
  factory ProductState.initial() => const ProductState();

  // Copy with
  ProductState copyWith({
    List<ProductModel>? products,
    int? selectedCategoryId,
    bool? isLoading,
    String? error,
    ProductViewMode? viewMode,
    bool? showExpired,
    bool clearError = false,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      viewMode: viewMode ?? this.viewMode,
      showExpired: showExpired ?? this.showExpired,
    );
  }

  // Get filtered products
  List<ProductModel> get filteredProducts {
    if (!showExpired) {
      return products;
    }
    // Filter by expire date (if needed)
    final now = DateTime.now();
    return products.where((product) {
      if (product.expireAt == null || product.expireAt!.isEmpty) {
        return true;
      }
      try {
        final expireDate = DateTime.parse(product.expireAt!);
        return expireDate.isBefore(now);
      } catch (e) {
        return true;
      }
    }).toList();
  }

  @override
  List<Object?> get props => [
        products,
        selectedCategoryId,
        isLoading,
        error,
        viewMode,
        showExpired,
      ];
}

