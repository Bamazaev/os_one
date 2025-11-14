import 'dart:typed_data';
import '../../../utils/base64_helper.dart';
import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../bloc/theme/theme_state.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final ThemeState themeState;
  final bool isDesktop;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showEditButtons;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
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
    final bool isExpired = product.expireAt != null && 
      DateTime.tryParse(product.expireAt!) != null &&
      DateTime.parse(product.expireAt!).isBefore(DateTime.now());
    
    return Card(
      elevation: isDesktop ? 8 : 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              // Product image
              RepaintBoundary(
                child: product.imageBase64 != null && product.imageBase64!.isNotEmpty
                    ? Image.memory(
                        safeBase64Decode(product.imageBase64!) ?? Uint8List(0),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              
              // Dark gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: isDesktop ? 160 : 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Info icon (top left)
              Positioned(
                top: isDesktop ? 10 : 6,
                left: isDesktop ? 10 : 6,
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 6 : 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: isDesktop ? 22 : 16,
                  ),
                ),
              ),
              
              // Price badge (top right)
              Positioned(
                top: isDesktop ? 10 : 6,
                right: isDesktop ? 10 : 6,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 8, 
                    vertical: isDesktop ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeState.primaryColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                    boxShadow: [
                      BoxShadow(
                        color: themeState.primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.salePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 16 : 13,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 2 : 1),
                      Text(
                        'сомони',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 9 : 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 12 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock badges (center)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stock badge (green)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 16 : 12, 
                                vertical: isDesktop ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeState.primaryColor,
                                borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
                              ),
                              child: Text(
                                '${product.stock.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 16 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : 6),
                            
                            // Stock sold badge (red)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 16 : 12, 
                                vertical: isDesktop ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
                              ),
                              child: Text(
                                '${product.stockSold.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 16 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : 6),
                            
                            // Unit badge (dark)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 14 : 10, 
                                vertical: isDesktop ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
                              ),
                              child: Text(
                                (product.unit != null && product.unit!.isNotEmpty) 
                                    ? product.unit!.toLowerCase() 
                                    : 'кг',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 14 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      
                      // Product name
                      Text(
                        product.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 16 : 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Product description
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        SizedBox(height: isDesktop ? 4 : 3),
                        Text(
                          product.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isDesktop ? 11 : 9,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                          maxLines: isDesktop ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Expired warning banner
              if (isExpired)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: isDesktop ? 6 : 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.95),
                          Colors.deepOrange.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          color: Colors.white,
                          size: isDesktop ? 14 : 12,
                        ),
                        SizedBox(width: isDesktop ? 6 : 4),
                        Text(
                          'ИСТЕК СРОК',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 11 : 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Dark overlay when edit mode
              if (showEditButtons)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(isDesktop ? 20 : 15),
                  ),
                ),
              
              // Edit/Delete buttons (centered)
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
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: isDesktop ? 60 : 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}

