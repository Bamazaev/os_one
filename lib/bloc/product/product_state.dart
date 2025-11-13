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
  final String searchQuery;
  final int syncedCount; // Количество синхронизированных операций

  const ProductState({
    this.products = const [],
    this.selectedCategoryId,
    this.isLoading = false,
    this.error,
    this.viewMode = ProductViewMode.grid,
    this.showExpired = false,
    this.searchQuery = '',
    this.syncedCount = 0,
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
    String? searchQuery,
    int? syncedCount,
    bool clearError = false,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      viewMode: viewMode ?? this.viewMode,
      showExpired: showExpired ?? this.showExpired,
      searchQuery: searchQuery ?? this.searchQuery,
      syncedCount: syncedCount ?? this.syncedCount,
    );
  }

  // Get filtered products (by search query and expire date)
  List<ProductModel> get filteredProducts {
    var filtered = products;
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.barcode.toLowerCase().contains(query) ||
               (product.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Filter by expire date (if needed)
    if (showExpired) {
      final now = DateTime.now();
      filtered = filtered.where((product) {
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
    
    return filtered;
  }

  @override
  List<Object?> get props => [
        products,
        selectedCategoryId,
        isLoading,
        error,
        viewMode,
        showExpired,
        searchQuery,
        syncedCount,
      ];
}

