import 'package:flutter_bloc/flutter_bloc.dart';
import 'category_event.dart';
import 'category_state.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/product_repository.dart';
import '../../services/hive_service.dart';
import '../../models/category_model.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;
  final ProductRepository productRepository;

  CategoryBloc({
    required this.categoryRepository,
    required this.productRepository,
  }) : super(CategoryState.initial()) {
    on<CategoriesLoadRequested>(_onCategoriesLoadRequested);
    on<CategoriesRefreshRequested>(_onCategoriesRefreshRequested);
    on<CategorySelected>(_onCategorySelected);
    on<CategoryAddRequested>(_onCategoryAddRequested);
    on<CategoryUpdateRequested>(_onCategoryUpdateRequested);
    on<CategoryDeleteRequested>(_onCategoryDeleteRequested);
  }

  // Load categories (from cache first, then Google Sheets)
  Future<void> _onCategoriesLoadRequested(
    CategoriesLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // First, load from cache for instant UI
      final cachedCategories = await HiveService.getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        // Update product counts for cached categories
        final cachedCategoriesWithCount = await _updateProductCounts(cachedCategories);
        emit(state.copyWith(
          categories: cachedCategoriesWithCount,
          isLoading: false,
        ));
      }

      // Then load from Google Sheets in background
      final categories = await categoryRepository.getAllCategories();
      
      // Calculate product count for each category
      final categoriesWithCount = await _updateProductCounts(categories);
      
      emit(state.copyWith(
        categories: categoriesWithCount,
        isLoading: false,
        error: null,
      ));

      print('✅ ${categories.length} категория загрузка шуд');
      
      // Try to sync pending operations in background
      _syncPendingOperations(emit);
    } catch (e) {
      print('❌ Хатои загрузкаи категорияҳо: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои загрузка: ${e.toString()}',
      ));
    }
  }

  // Refresh categories from Google Sheets
  Future<void> _onCategoriesRefreshRequested(
    CategoriesRefreshRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Force refresh from Google Sheets (skip cache)
      final categories = await categoryRepository.getAllCategoriesForceRefresh();
      
      // Calculate product count for each category
      final categoriesWithCount = await _updateProductCounts(categories);
      
      emit(state.copyWith(
        categories: categoriesWithCount,
        isLoading: false,
        error: null,
      ));

      print('✅ Категорияҳо refresh шуданд (force from Google Sheets)');
    } catch (e) {
      print('❌ Хатои refresh: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои refresh: ${e.toString()}',
      ));
    }
  }

  // Select category
  Future<void> _onCategorySelected(
    CategorySelected event,
    Emitter<CategoryState> emit,
  ) async {
    // If categoryId is 0, it means "All products" - clear selected category
    if (event.categoryId == 0) {
      emit(state.copyWith(clearSelectedCategory: true));
      print('✅ Категория интихоб шуд: Ҳамаи маҳсулот');
    } else {
      // Update selected category immediately (no async delay - products will load faster)
      emit(state.copyWith(selectedCategoryId: event.categoryId));
      print('✅ Категория интихоб шуд: ${event.categoryId}');
      
      // Note: Product counts will be updated when categories are refreshed
      // This avoids blocking the UI when selecting a category
    }
  }

  // Add new category
  Future<void> _onCategoryAddRequested(
    CategoryAddRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('📝 Илова кардани категория: ${event.name}');

      // Generate ID - use seconds since epoch to keep it within int32 range
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Take only last 8 digits to ensure it fits in Hive int range
      final id = timestamp % 100000000; // Max ~100 million, safe for Hive

      // Get next position
      final maxPosition = state.categories.isEmpty 
          ? 0 
          : state.categories.map((c) => c.position).reduce((a, b) => a > b ? a : b);
      final position = maxPosition + 1;

      // Create new category
      final newCategory = CategoryModel(
        id: id,
        name: event.name,
        imageBase64: event.imageBase64,
        productCount: 0,
        position: position,
      );

      print('🆔 ID: $id, Position: $position');

      // Save to Google Sheets (or offline queue if no internet)
      final success = await categoryRepository.addCategory(newCategory);

      // Refresh categories (from cache if offline, from Google Sheets if online)
      final updatedCategories = await categoryRepository.getAllCategories();
      
      // Calculate product count for each category
      final categoriesWithCount = await _updateProductCounts(updatedCategories);
      
      emit(state.copyWith(
        categories: categoriesWithCount,
        isLoading: false,
        error: null,
      ));
      
      if (success) {
        print('✅ Категория "${event.name}" илова шуд в Google Sheets');
      } else {
        print('📝 Категория "${event.name}" сохранена офлайн (будет синхронизирована при появлении интернета)');
        // Try to sync pending operations in background (no emit needed here, will be called on next load)
      }
    } catch (e) {
      print('❌ Хатои илова кардани категория: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои илова кардани категория: ${e.toString()}',
      ));
    }
  }

  // Update existing category
  Future<void> _onCategoryUpdateRequested(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('✏️ Навсозии категория: ${event.name}');

      // Find existing category
      final existingCategory = state.categories.firstWhere(
        (c) => c.id == event.id,
        orElse: () => CategoryModel(
          id: event.id,
          name: event.name,
          imageBase64: event.imageBase64,
          productCount: 0,
          position: 0,
        ),
      );

      // Create updated category
      final updatedCategory = CategoryModel(
        id: event.id,
        name: event.name,
        imageBase64: event.imageBase64 ?? existingCategory.imageBase64,
        productCount: existingCategory.productCount,
        position: existingCategory.position,
      );

      // Update in Google Sheets
      final success = await categoryRepository.updateCategory(updatedCategory);

      if (success) {
        // Refresh categories from Google Sheets
        final updatedCategories = await categoryRepository.getAllCategories();
        
        // Calculate product count for each category
        final categoriesWithCount = await _updateProductCounts(updatedCategories);
        
        emit(state.copyWith(
          categories: categoriesWithCount,
          isLoading: false,
          error: null,
        ));
        print('✅ Категория "${event.name}" навсозӣ шуд');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Хатогӣ дар навсозии категория',
        ));
        print('❌ Категорияро навсозӣ карда натавонист');
      }
    } catch (e) {
      print('❌ Хатои навсозии категория: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои навсозии категория: ${e.toString()}',
      ));
    }
  }

  // Delete category
  Future<void> _onCategoryDeleteRequested(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      print('🗑️ Нест кардани категория бо ID: ${event.id}');

      // Delete from Google Sheets
      final success = await categoryRepository.deleteCategory(event.id);

      if (success) {
        // Refresh categories from Google Sheets
        final updatedCategories = await categoryRepository.getAllCategories();
        
        // Calculate product count for each category
        final categoriesWithCount = await _updateProductCounts(updatedCategories);
        
        emit(state.copyWith(
          categories: categoriesWithCount,
          isLoading: false,
          error: null,
        ));
        print('✅ Категория бо ID ${event.id} нест шуд');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Хатогӣ дар нест кардани категория',
        ));
        print('❌ Категорияро нест карда натавонист');
      }
    } catch (e) {
      print('❌ Хатои нест кардани категория: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Хатои нест кардани категория: ${e.toString()}',
      ));
    }
  }

  // Helper method to update product counts for categories
  Future<List<CategoryModel>> _updateProductCounts(List<CategoryModel> categories) async {
    try {
      // Get all products
      final result = await productRepository.getAllProductsWithCacheInfo();
      final products = result.products;

      print('📊 Обновление счетчиков: всего продуктов ${products.length}');

      // Count products for each category by categoryId
      final updatedCategories = categories.map((category) {
        final count = products.where((product) {
          // Compare categoryId (int) with category.id (int)
          return product.categoryId == category.id;
        }).length;
        
        if (count > 0) {
          print('  ✅ Категория "${category.name}" (ID: ${category.id}): $count продуктов');
        }
        
        return category.copyWith(productCount: count);
      }).toList();

      print('📊 Обновлены счетчики продуктов для ${updatedCategories.length} категорий');
      return updatedCategories;
    } catch (e) {
      print('❌ Хатои подсчета продуктов: $e');
      // Return categories without updating counts if error
      return categories;
    }
  }

  // Sync pending operations from offline queue
  Future<void> _syncPendingOperations(Emitter<CategoryState> emit) async {
    try {
      final pendingOps = await HiveService.getPendingOperations();
      final categoryOps = pendingOps.where((op) => 
        op['type'] == 'add_category' || 
        op['type'] == 'update_category' || 
        op['type'] == 'delete_category'
      ).toList();
      
      if (categoryOps.isEmpty) return;

      print('🔄 Синхронизация ${categoryOps.length} операций категорий из очереди...');
      int syncedCount = 0;
      final allOps = await HiveService.getPendingOperations();

      for (var op in categoryOps) {
        final type = op['type'] as String;
        final data = Map<String, dynamic>.from(op['data'] as Map);

        try {
          bool success = false;
          if (type == 'add_category') {
            final category = CategoryModel.fromMap(data);
            success = await categoryRepository.addCategory(category);
          } else if (type == 'update_category') {
            final category = CategoryModel.fromMap(data);
            success = await categoryRepository.updateCategory(category);
          } else if (type == 'delete_category') {
            final id = data['id'] as int;
            success = await categoryRepository.deleteCategory(id);
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
        print('✅ Синхронизировано $syncedCount операций категорий');
        // Refresh categories after sync
        final updatedCategories = await categoryRepository.getAllCategories();
        final categoriesWithCount = await _updateProductCounts(updatedCategories);
        emit(state.copyWith(
          categories: categoriesWithCount,
          syncedCount: syncedCount, // Notify UI about sync
        ));
      }
    } catch (e) {
      print('❌ Ошибка синхронизации: $e');
    }
  }
}

