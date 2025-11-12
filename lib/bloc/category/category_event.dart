import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

// Load categories from Google Sheets
class CategoriesLoadRequested extends CategoryEvent {
  const CategoriesLoadRequested();
}

// Refresh categories
class CategoriesRefreshRequested extends CategoryEvent {
  const CategoriesRefreshRequested();
}

// Select category
class CategorySelected extends CategoryEvent {
  final int categoryId;

  const CategorySelected(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

// Add new category
class CategoryAddRequested extends CategoryEvent {
  final String name;
  final String? imageBase64;

  const CategoryAddRequested({
    required this.name,
    this.imageBase64,
  });

  @override
  List<Object?> get props => [name, imageBase64];
}

// Update existing category
class CategoryUpdateRequested extends CategoryEvent {
  final int id;
  final String name;
  final String? imageBase64;

  const CategoryUpdateRequested({
    required this.id,
    required this.name,
    this.imageBase64,
  });

  @override
  List<Object?> get props => [id, name, imageBase64];
}

// Delete category
class CategoryDeleteRequested extends CategoryEvent {
  final int id;

  const CategoryDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

