import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';

class CategoryState extends Equatable {
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.selectedCategoryId,
    this.isLoading = false,
    this.error,
  });

  // Initial state
  factory CategoryState.initial() => const CategoryState();

  // Loading state
  CategoryState copyWith({
    List<CategoryModel>? categories,
    int? selectedCategoryId,
    bool? isLoading,
    String? error,
    bool clearSelectedCategory = false,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedCategoryId: clearSelectedCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Get selected category
  CategoryModel? get selectedCategory {
    if (selectedCategoryId == null) return null;
    try {
      return categories.firstWhere((cat) => cat.id == selectedCategoryId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [categories, selectedCategoryId, isLoading, error];
}

