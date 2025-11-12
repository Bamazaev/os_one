import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../../repositories/product_repository.dart';
import '../../models/product_model.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository}) : super(ProductState.initial()) {
    on<ProductsLoadRequested>(_onProductsLoadRequested);
    on<ProductsLoadByCategory>(_onProductsLoadByCategory);
    on<ProductAddRequested>(_onProductAddRequested);
    on<ProductUpdateRequested>(_onProductUpdateRequested);
    on<ProductDeleteRequested>(_onProductDeleteRequested);
    on<ProductViewModeToggled>(_onProductViewModeToggled);
    on<ProductFilterByExpireDate>(_onProductFilterByExpireDate);
  }

  // Load all products
  Future<void> _onProductsLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('📦 Бор кардани продуктҳо...');

      final products = await productRepository.getAllProducts();
      
      emit(state.copyWith(
        products: products,
        isLoading: false,
        error: null,
      ));
      print('✅ ${products.length} продукт бор шуд');
    } catch (e) {
      print('❌ Хатои бор кардани продуктҳо: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатогӣ дар бор кардани продуктҳо: ${e.toString()}',
      ));
    }
  }

  // Load products by category
  Future<void> _onProductsLoadByCategory(
    ProductsLoadByCategory event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('📦 Бор кардани продуктҳо барои категория ${event.categoryId}...');

      final products = await productRepository.getProductsByCategory(event.categoryId);
      
      emit(state.copyWith(
        products: products,
        selectedCategoryId: event.categoryId,
        isLoading: false,
        error: null,
      ));
      print('✅ ${products.length} продукт бор шуд');
    } catch (e) {
      print('❌ Хатои бор кардани продуктҳо: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатогӣ дар бор кардани продуктҳо: ${e.toString()}',
      ));
    }
  }

  // Add new product
  Future<void> _onProductAddRequested(
    ProductAddRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('📝 Илова кардани продукт: ${event.name}');

      // Generate ID (timestamp)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final id = timestamp % 100000000;

      // Get next position
      final maxPosition = state.products.isEmpty
          ? 0
          : state.products.map((p) => p.position).reduce((a, b) => a > b ? a : b);
      final position = maxPosition + 1;

      // Create new product
      final newProduct = ProductModel(
        id: id,
        barcode: event.barcode,
        categoryId: event.categoryId,
        name: event.name,
        imageBase64: event.imageBase64,
        description: event.description,
        stock: event.stock,
        purchasePrice: event.purchasePrice,
        salePrice: event.salePrice,
        position: position,
        expireAt: event.expireAt,
        piece: event.piece,
        unit: event.unit,
      );

      // Save to Google Sheets
      final success = await productRepository.addProduct(newProduct);

      if (success) {
        // Reload products
        final updatedProducts = state.selectedCategoryId != null
            ? await productRepository.getProductsByCategory(state.selectedCategoryId!)
            : await productRepository.getAllProducts();
        
        emit(state.copyWith(
          products: updatedProducts,
          isLoading: false,
          error: null,
        ));
        print('✅ Продукт "${event.name}" илова шуд');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Хатогӣ дар илова кардани продукт',
        ));
        print('❌ Продуктро илова карда натавонист');
      }
    } catch (e) {
      print('❌ Хатои илова кардани продукт: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои илова кардани продукт: ${e.toString()}',
      ));
    }
  }

  // Update product
  Future<void> _onProductUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('✏️ Навсозии продукт: ${event.name}');

      final existingProduct = state.products.firstWhere(
        (p) => p.id == event.id,
        orElse: () => ProductModel(
          id: event.id,
          barcode: event.barcode,
          categoryId: event.categoryId,
          name: event.name,
          purchasePrice: event.purchasePrice,
          salePrice: event.salePrice,
          stock: event.stock,
          position: 0,
        ),
      );

      final updatedProduct = existingProduct.copyWith(
        barcode: event.barcode,
        categoryId: event.categoryId,
        name: event.name,
        imageBase64: event.imageBase64,
        description: event.description,
        stock: event.stock,
        purchasePrice: event.purchasePrice,
        salePrice: event.salePrice,
        expireAt: event.expireAt,
        piece: event.piece,
        unit: event.unit,
      );

      final success = await productRepository.updateProduct(updatedProduct);

      if (success) {
        final updatedProducts = state.selectedCategoryId != null
            ? await productRepository.getProductsByCategory(state.selectedCategoryId!)
            : await productRepository.getAllProducts();
        
        emit(state.copyWith(
          products: updatedProducts,
          isLoading: false,
          error: null,
        ));
        print('✅ Продукт "${event.name}" навсозӣ шуд');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Хатогӣ дар навсозии продукт',
        ));
      }
    } catch (e) {
      print('❌ Хатои навсозии продукт: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои навсозии продукт: ${e.toString()}',
      ));
    }
  }

  // Delete product
  Future<void> _onProductDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('🗑️ Нест кардани продукт: ${event.id}');

      final success = await productRepository.deleteProduct(event.id);

      if (success) {
        final updatedProducts = state.selectedCategoryId != null
            ? await productRepository.getProductsByCategory(state.selectedCategoryId!)
            : await productRepository.getAllProducts();
        
        emit(state.copyWith(
          products: updatedProducts,
          isLoading: false,
          error: null,
        ));
        print('✅ Продукт нест шуд');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Хатогӣ дар нест кардани продукт',
        ));
      }
    } catch (e) {
      print('❌ Хатои нест кардани продукт: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои нест кардани продукт: ${e.toString()}',
      ));
    }
  }

  // Toggle view mode
  void _onProductViewModeToggled(
    ProductViewModeToggled event,
    Emitter<ProductState> emit,
  ) {
    final newMode = state.viewMode == ProductViewMode.grid
        ? ProductViewMode.list
        : ProductViewMode.grid;
    
    emit(state.copyWith(viewMode: newMode));
    print('🔄 View mode: $newMode');
  }

  // Filter by expire date
  void _onProductFilterByExpireDate(
    ProductFilterByExpireDate event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(showExpired: event.showExpired));
    print('📅 Show expired: ${event.showExpired}');
  }
}

