import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/product/product_bloc.dart';
import '../../../bloc/product/product_event.dart';
import '../../../bloc/product/product_state.dart';
import '../../../bloc/category/category_bloc.dart';
import '../../../bloc/category/category_event.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../models/product_model.dart';
import 'product_card.dart';

class ProductsSection extends StatefulWidget {
  final ThemeState themeState;
  final bool isDesktop;
  final int? selectedProductForEdit;
  final Function(int?) onEditModeChanged;
  final Function(BuildContext, ThemeState) onAddProduct;
  final Function(BuildContext, ThemeState, ProductModel) onEditProduct;
  final Function(BuildContext, ThemeState, ProductModel) onDeleteProduct;

  const ProductsSection({
    super.key,
    required this.themeState,
    required this.isDesktop,
    required this.selectedProductForEdit,
    required this.onEditModeChanged,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<ProductsSection> {
  bool _operationInProgress = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, productState) {
        // When operation completes successfully (no error, not loading)
        // Hide loading SnackBar and show success message
        if (_operationInProgress && !productState.isLoading && productState.error == null) {
          // Update category product counts
          context.read<CategoryBloc>().add(const CategoriesRefreshRequested());
          
          // Small delay to ensure products are updated
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              // Hide any existing SnackBar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '✅ Операция выполнена успешно!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: widget.themeState.primaryColor,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
          _operationInProgress = false;
        }

        // Track loading state (for initial load from network)
        if (productState.isLoading) {
          _operationInProgress = true;
        }

        // Show error if any
        if (productState.error != null && productState.error!.isNotEmpty) {
          // Hide loading SnackBar if error occurs
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      productState.error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          _operationInProgress = false;
        }
        
        // Show success message after sync
        if (productState.syncedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ ${productState.syncedCount} операция(й) синхронизирована в Google Sheets',
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
      builder: (context, productState) {
        return Column(
          children: [
            // Products header with buttons
            Row(
              children: [
                Text(
                  'Продукты',
                  style: TextStyle(
                    color: widget.themeState.textColor,
                    fontSize: widget.isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Add product button
                IconButton(
                  onPressed: () => widget.onAddProduct(context, widget.themeState),
                  icon: Icon(Icons.add_circle, color: widget.themeState.primaryColor),
                  tooltip: 'Добавить продукт',
                ),
                // Filter by expire date
                IconButton(
                  onPressed: () {
                    context.read<ProductBloc>().add(
                      ProductFilterByExpireDate(!productState.showExpired),
                    );
                  },
                  icon: Icon(
                    Icons.calendar_today,
                    color: productState.showExpired 
                        ? widget.themeState.primaryColor 
                        : widget.themeState.secondaryTextColor,
                  ),
                  tooltip: 'Фильтр по сроку',
                ),
                // Toggle view mode
                IconButton(
                  onPressed: () {
                    context.read<ProductBloc>().add(const ProductViewModeToggled());
                  },
                  icon: Icon(
                    productState.viewMode == ProductViewMode.grid
                        ? Icons.view_list
                        : Icons.grid_view,
                    color: widget.themeState.secondaryTextColor,
                  ),
                  tooltip: productState.viewMode == ProductViewMode.grid
                      ? 'Список'
                      : 'Сетка',
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Products grid (with pull-to-refresh)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Force refresh from Google Sheets (not from cache)
                  context.read<ProductBloc>().add(const ProductsLoadRequested(forceRefresh: true));
                  // Also refresh categories to update product counts
                  context.read<CategoryBloc>().add(const CategoriesRefreshRequested());
                  // Wait a bit for the refresh to complete
                  await Future.delayed(const Duration(milliseconds: 1000));
                },
                color: widget.themeState.primaryColor,
                child: Stack(
                  children: [
                    // Products content (always visible, even during loading)
                    productState.filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 80,
                                  color: widget.themeState.secondaryTextColor,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Продуктов пока нет',
                                  style: TextStyle(
                                    color: widget.themeState.textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Нажмите + чтобы добавить',
                                  style: TextStyle(
                                    color: widget.themeState.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: widget.isDesktop ? 4 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: widget.isDesktop ? 0.85 : 1.0,
                          ),
                          itemCount: productState.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = productState.filteredProducts[index];
                            final showEditButtons = widget.selectedProductForEdit == product.id;
                            
                            return ProductCard(
                              product: product,
                              themeState: widget.themeState,
                              isDesktop: widget.isDesktop,
                              showEditButtons: showEditButtons,
                              onTap: () {
                                if (widget.selectedProductForEdit == product.id) {
                                  // If edit mode, cancel it
                                  widget.onEditModeChanged(null);
                                } else {
                                  // Normal tap - show product info
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Просмотр: ${product.name}'),
                                      backgroundColor: widget.themeState.primaryColor,
                                      duration: const Duration(milliseconds: 800),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                // Toggle edit mode
                                if (widget.selectedProductForEdit == product.id) {
                                  widget.onEditModeChanged(null);
                                } else {
                                  widget.onEditModeChanged(product.id);
                                }
                              },
                              onEdit: () {
                                widget.onEditProduct(context, widget.themeState, product);
                              },
                              onDelete: () {
                                widget.onDeleteProduct(context, widget.themeState, product);
                              },
                            );
                          },
                        ),
                  
                  // Background loading indicator (only when loading, doesn't block UI)
                  if (productState.isLoading)
                    Positioned.fill(
                      child: Container(
                        color: widget.themeState.backgroundColor.withOpacity(0.7),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(widget.themeState.primaryColor),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

