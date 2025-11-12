import 'package:flutter_bloc/flutter_bloc.dart';
import 'category_event.dart';
import 'category_state.dart';
import '../../repositories/category_repository.dart';
import '../../services/hive_service.dart';
import '../../models/category_model.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository}) : super(CategoryState.initial()) {
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
        emit(state.copyWith(
          categories: cachedCategories,
          isLoading: false,
        ));
      }

      // Then load from Google Sheets in background
      final categories = await categoryRepository.getAllCategories();
      emit(state.copyWith(
        categories: categories,
        isLoading: false,
        error: null,
      ));

      print('✅ ${categories.length} категория загрузка шуд');
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
      final categories = await categoryRepository.getAllCategories();
      emit(state.copyWith(
        categories: categories,
        isLoading: false,
        error: null,
      ));

      print('✅ Категорияҳо refresh шуданд');
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
      emit(state.copyWith(selectedCategoryId: event.categoryId));
      print('✅ Категория интихоб шуд: ${event.categoryId}');
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

      // Save to Google Sheets
      final success = await categoryRepository.addCategory(newCategory);

      if (success) {
        // Refresh categories from Google Sheets
        final updatedCategories = await categoryRepository.getAllCategories();
        emit(state.copyWith(
          categories: updatedCategories,
          isLoading: false,
          error: null,
        ));
        print('✅ Категория "${event.name}" илова шуд');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Хатогӣ дар илова кардани категория',
        ));
        print('❌ Категорияро илова карда натавонист');
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
        emit(state.copyWith(
          categories: updatedCategories,
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
        emit(state.copyWith(
          categories: updatedCategories,
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
}

