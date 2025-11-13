import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../bloc/theme/theme_state.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final ThemeState themeState;
  final bool isDesktop;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showEditButtons;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.themeState,
    required this.isDesktop,
    required this.onTap,
    required this.onLongPress,
    required this.showEditButtons,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final size = isDesktop ? 130.0 : 110.0;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: size,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: themeState.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? themeState.primaryColor : themeState.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? themeState.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background image
            if (category.imageBase64 != null && category.imageBase64!.isNotEmpty)
              RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(category.imageBase64!),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    cacheWidth: (size * 2).toInt(),
                    cacheHeight: (size * 2).toInt(),
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(size);
                    },
                  ),
                ),
              )
            else
              _buildDefaultIcon(size),
            
            // Dark overlay
            RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Green overlay (when selected)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeState.primaryColor.withOpacity(0.3),
                      themeState.primaryColor.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),
            
            // Category name
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: RepaintBoundary(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 14 : 10,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Product count badge - always show, even if 0
            if (!showEditButtons)
              Positioned(
                top: 0,
                right: 0,
                child: RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: category.productCount > 0 
                          ? Colors.green.withOpacity(0.9)
                          : Colors.grey.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${category.productCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Dark overlay when edit mode
            if (showEditButtons)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
            
            // Edit/Delete buttons
            if (showEditButtons)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Edit button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeState.primaryColor.withOpacity(0.3),
            themeState.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.category,
        size: 40,
        color: themeState.primaryColor,
      ),
    );
  }
}

