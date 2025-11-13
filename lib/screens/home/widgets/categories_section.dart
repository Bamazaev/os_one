import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../../../bloc/category/category_bloc.dart';
import '../../../bloc/category/category_event.dart';
import '../../../bloc/category/category_state.dart';
import '../../../bloc/product/product_bloc.dart';
import '../../../bloc/product/product_event.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../models/category_model.dart';
import 'category_card.dart';

class CategoriesSection extends StatelessWidget {
  final ThemeState themeState;
  final bool isDesktop;
  final int? selectedCategoryForEdit;
  final Function(int?) onEditModeChanged;
  final Function(BuildContext, ThemeState) onAddCategory;
  final Function(BuildContext, ThemeState, CategoryModel) onEditCategory;
  final Function(BuildContext, ThemeState, CategoryModel) onDeleteCategory;

  const CategoriesSection({
    super.key,
    required this.themeState,
    required this.isDesktop,
    required this.selectedCategoryForEdit,
    required this.onEditModeChanged,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, categoryState) {
        if (categoryState.error != null && categoryState.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(categoryState.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        // Show success message after sync
        if (categoryState.syncedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ ${categoryState.syncedCount} операция(й) синхронизирована в Google Sheets',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, categoryState) {
        if (categoryState.isLoading && categoryState.categories.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Категории" title
            Text(
              'Категории',
              style: TextStyle(
                color: themeState.textColor,
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            
            // Horizontal scrolling categories (with pull-to-refresh)
            SizedBox(
              height: isDesktop ? 140 : 120,
              child: RefreshIndicator(
                onRefresh: () async {
                  // Force refresh from Google Sheets (not from cache)
                  context.read<CategoryBloc>().add(const CategoriesRefreshRequested());
                  // Also refresh products to update counts
                  context.read<ProductBloc>().add(const ProductsLoadRequested());
                  // Wait a bit for the refresh to complete
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: themeState.primaryColor,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryState.categories.length + 2, // +1 for "Все продукты", +1 for "Add button"
                  itemBuilder: (context, index) {
                  // First item - "Все продукты"
                  if (index == 0) {
                    final isSelected = categoryState.selectedCategoryId == null || categoryState.selectedCategoryId == 0;
                    return _buildAllProductsCard(
                      isSelected: isSelected,
                      themeState: themeState,
                      isDesktop: isDesktop,
                      onTap: () {
                        context.read<CategoryBloc>().add(
                          const CategorySelected(0), // 0 means all products
                        );
                        // Load all products
                        context.read<ProductBloc>().add(
                          const ProductsLoadByCategory(0),
                        );
                      },
                    );
                  }
                  
                  // Last item - "Add category" button
                  if (index == categoryState.categories.length + 1) {
                    return _buildAddCategoryButton(
                      themeState: themeState,
                      isDesktop: isDesktop,
                      context: context,
                    );
                  }
                  
                  // Other categories
                  final category = categoryState.categories[index - 1];
                  final isSelected = categoryState.selectedCategoryId == category.id;
                  final showEditButtons = selectedCategoryForEdit == category.id;
                  
                  return CategoryCard(
                    category: category,
                    isSelected: isSelected,
                    themeState: themeState,
                    isDesktop: isDesktop,
                    showEditButtons: showEditButtons,
                    onTap: () {
                      if (selectedCategoryForEdit == category.id) {
                        // If edit mode, cancel it
                        onEditModeChanged(null);
                      } else {
                        // Normal category selection
                        context.read<CategoryBloc>().add(
                          CategorySelected(category.id),
                        );
                        // Load products for this category
                        context.read<ProductBloc>().add(
                          ProductsLoadByCategory(category.id),
                        );
                      }
                    },
                    onLongPress: () {
                      // Toggle edit mode
                      if (selectedCategoryForEdit == category.id) {
                        onEditModeChanged(null);
                      } else {
                        onEditModeChanged(category.id);
                      }
                    },
                    onEdit: () {
                      onEditCategory(context, themeState, category);
                    },
                    onDelete: () {
                      onDeleteCategory(context, themeState, category);
                    },
                  );
                },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllProductsCard({
    required bool isSelected,
    required ThemeState themeState,
    required bool isDesktop,
    required VoidCallback onTap,
  }) {
    final size = isDesktop ? 130.0 : 110.0;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            width: size,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        themeState.primaryColor,
                        themeState.primaryColor.withOpacity(0.7),
                      ]
                    : [
                        themeState.primaryColor.withOpacity(0.3),
                        themeState.primaryColor.withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? themeState.primaryColor : themeState.borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? themeState.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 15 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/logo/logo_white no back.svg',
                  width: 60,
                  height: 60,
                  colorFilter: ColorFilter.mode(
                    isSelected ? Colors.white : themeState.textColor,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Все продукты',
                  style: TextStyle(
                    color: isSelected ? Colors.white : themeState.textColor,
                    fontSize: isDesktop ? 16 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton({
    required ThemeState themeState,
    required bool isDesktop,
    required BuildContext context,
  }) {
    final size = isDesktop ? 130.0 : 110.0;
    
    return GestureDetector(
      onTap: () => onAddCategory(context, themeState),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeState.primaryColor.withOpacity(0.15),
              themeState.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: themeState.primaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeState.primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeState.primaryColor,
                    themeState.primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Добавить',
              style: TextStyle(
                color: themeState.textColor,
                fontSize: isDesktop ? 14 : 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

