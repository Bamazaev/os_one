import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../../repositories/product_repository.dart';
import '../../models/product_model.dart';
import '../../services/hive_service.dart';

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
    on<ProductSearchRequested>(_onProductSearchRequested);
  }

  // Load all products
  Future<void> _onProductsLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      print('📦 Бор кардани продуктҳо...');

      // Check if this is a force refresh (from pull-to-refresh)
      final isForceRefresh = event.forceRefresh ?? false;
      
      // Get products with cache info (force refresh if needed)
      final result = isForceRefresh
          ? await productRepository.getAllProductsWithCacheInfoForceRefresh()
          : await productRepository.getAllProductsWithCacheInfo();
      
      // Only show loading if loading from network (not from cache)
      if (!result.fromCache) {
        emit(state.copyWith(isLoading: true));
      }
      
      emit(state.copyWith(
        products: result.products,
        isLoading: false,
        error: null,
      ));
      
      if (result.fromCache && !isForceRefresh) {
        print('✅ ${result.products.length} продукт аз cache бор шуд (loading indicator намешавад)');
      } else {
        print('✅ ${result.products.length} продукт аз Google Sheets бор шуд${isForceRefresh ? " (force refresh)" : ""}');
      }
      
      // Try to sync pending operations in background
      _syncPendingOperations(emit);
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
      // If we already have products loaded and just filtering, do it instantly
      if (state.products.isNotEmpty && !state.isLoading) {
        List<ProductModel> filteredProducts;
        if (event.categoryId == 0) {
          // Get all products from repository (might need to reload)
          final result = await productRepository.getAllProductsWithCacheInfo();
          filteredProducts = result.products;
        } else {
          // Fast filter from current state
          filteredProducts = state.products.where((p) => p.categoryId == event.categoryId).toList();
          
          // If no products found in current state, reload from repository
          if (filteredProducts.isEmpty) {
            final result = await productRepository.getAllProductsWithCacheInfo();
            filteredProducts = result.products.where((p) => p.categoryId == event.categoryId).toList();
          }
        }
        
        // Update state immediately (no loading indicator)
        emit(state.copyWith(
          products: filteredProducts,
          selectedCategoryId: event.categoryId,
          isLoading: false,
          error: null,
        ));
        return;
      }

      // First time load or reload needed
      print('📦 Бор кардани продуктҳо барои категория ${event.categoryId}...');

      // Get all products with cache info
      final result = await productRepository.getAllProductsWithCacheInfo();
      
      // Filter by category (optimized - no debug logs in production)
      List<ProductModel> products;
      if (event.categoryId == 0) {
        products = result.products;
      } else {
        products = result.products.where((p) => p.categoryId == event.categoryId).toList();
      }
      
      // Only show loading if loading from network (not from cache)
      if (!result.fromCache) {
        emit(state.copyWith(isLoading: true));
      }
      
      emit(state.copyWith(
        products: products,
        selectedCategoryId: event.categoryId,
        isLoading: false,
        error: null,
      ));
      
      if (result.fromCache) {
        print('✅ ${products.length} продукт аз cache бор шуд');
      } else {
        print('✅ ${products.length} продукт аз Google Sheets бор шуд');
      }
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
      // Don't set isLoading to avoid global refresh indicator
      print('📝 Илова кардани продукт: ${event.product.name}');

      // Save to Google Sheets (or offline queue if no internet)
      final success = await productRepository.addProduct(event.product);

      // Reload products (from cache if offline, from Google Sheets if online)
      final updatedProducts = await productRepository.getAllProducts();
      
      emit(state.copyWith(
        products: updatedProducts,
        isLoading: false,
        error: null,
      ));
      
      if (success) {
        print('✅ Продукт "${event.product.name}" илова шуд в Google Sheets');
      } else {
        print('📝 Продукт "${event.product.name}" сохранен офлайн (будет синхронизирован при появлении интернета)');
        // Try to sync pending operations in background (no emit needed here, will be called on next load)
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
      // Don't set isLoading to avoid global refresh indicator
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
      // Don't set isLoading to avoid global refresh indicator
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

  // Search products
  void _onProductSearchRequested(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    print('🔍 Поиск: "${event.query}"');
  }

  // Sync pending operations from offline queue
  Future<void> _syncPendingOperations(Emitter<ProductState> emit) async {
    try {
      final pendingOps = await HiveService.getPendingOperations();
      final productOps = pendingOps.where((op) => 
        op['type'] == 'add_product' || 
        op['type'] == 'update_product' || 
        op['type'] == 'delete_product'
      ).toList();
      
      if (productOps.isEmpty) return;

      print('🔄 Синхронизация ${productOps.length} операций продуктов из очереди...');
      int syncedCount = 0;
      final allOps = await HiveService.getPendingOperations();

      for (var op in productOps) {
        final type = op['type'] as String;
        final data = Map<String, dynamic>.from(op['data'] as Map);

        try {
          bool success = false;
          if (type == 'add_product') {
            final product = ProductModel.fromMap(data);
            success = await productRepository.addProduct(product);
          } else if (type == 'update_product') {
            final product = ProductModel.fromMap(data);
            success = await productRepository.updateProduct(product);
          } else if (type == 'delete_product') {
            final id = data['id'] as int;
            success = await productRepository.deleteProduct(id);
          }

          if (success) {
            // Find and remove from queue
            final index = allOps.indexWhere((o) => o['timestamp'] == op['timestamp']);
            if (index >= 0) {
              await HiveService.removePendingOperationByIndex(index);
            }
            syncedCount++;
            print('✅ Синхронизирована операция: $type');
          }
        } catch (e) {
          print('⚠️ Ошибка синхронизации операции $type: $e');
        }
      }

      if (syncedCount > 0) {
        print('✅ Синхронизировано $syncedCount операций продуктов');
        // Refresh products after sync
        final updatedProducts = await productRepository.getAllProducts();
        emit(state.copyWith(
          products: updatedProducts,
          syncedCount: syncedCount, // Notify UI about sync
        ));
      }
    } catch (e) {
      print('❌ Ошибка синхронизации: $e');
    }
  }
}

