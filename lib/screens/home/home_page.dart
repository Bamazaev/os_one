import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_event.dart';
import '../../bloc/category/category_state.dart';
import '../../models/category_model.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../models/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _selectedCategoryForEdit; // ID of category being edited/deleted

  Widget _buildCategoryCard({
    required CategoryModel category,
    required bool isSelected,
    required ThemeState themeState,
    required bool isDesktop,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required bool showEditButtons,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final size = isDesktop ? 130.0 : 110.0;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque, // Prevent tap from passing through
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
            // Background image (with RepaintBoundary to prevent flickering)
            if (category.imageBase64 != null && category.imageBase64!.isNotEmpty)
              RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(category.imageBase64!),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    cacheWidth: (size * 2).toInt(), // Cache for better performance
                    cacheHeight: (size * 2).toInt(),
                    gaplessPlayback: true, // Prevent flickering
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultCategoryIcon(themeState, size);
                    },
                  ),
                ),
              )
            else
              _buildDefaultCategoryIcon(themeState, size),
            
            // Dark overlay (always present) - with RepaintBoundary
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
            
            // Green overlay (only when selected) - animated
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
                      Colors.transparent,
                      themeState.primaryColor.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            
            // Category name (with RepaintBoundary)
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
            
            // Product count badge (with RepaintBoundary)
            if (category.productCount > 0 && !showEditButtons)
              Positioned(
                top: 0,
                right: 0,
                child: RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeState.primaryColor.withOpacity(0.8),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: Text(
                      '${category.productCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Dark overlay when edit mode is active
            if (showEditButtons)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
            
            // Edit/Delete buttons (shown when long pressed) - centered
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

  Widget _buildDefaultCategoryIcon(ThemeState themeState, double size) {
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
      child: Container(
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
            SvgPicture.asset('assets/logo/logo_white no back.svg', width: 60, height: 60, colorFilter: ColorFilter.mode(isSelected ? Colors.white : themeState.textColor, BlendMode.srcIn),),
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
    );
  }

  Widget _buildAddCategoryButton({
    required ThemeState themeState,
    required bool isDesktop,
    required BuildContext context,
  }) {
    final size = isDesktop ? 130.0 : 110.0;
    
    return GestureDetector(
      onTap: () => _showAddCategoryDialog(context, themeState),
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
                boxShadow: [
                  BoxShadow(
                    color: themeState.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Добавить',
              style: TextStyle(
                color: themeState.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, ThemeState themeState) {
    final nameController = TextEditingController();
    String? selectedImageBase64;
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: themeState.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeState.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.category,
                    color: themeState.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Новая категория',
                  style: TextStyle(
                    color: themeState.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image picker - FIRST
                  Text(
                    'Изображение категории',
                    style: TextStyle(
                      color: themeState.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      print('🖼️ Интихоби тасвир сар шуд...');
                      final result = await _pickCategoryImage();
                      if (result != null) {
                        print('✅ Натиҷа гирифта шуд');
                        setState(() {
                          imageBytes = result['bytes'];
                          selectedImageBase64 = result['base64'];
                          print('✅ setState: imageBytes = ${imageBytes?.length ?? 0} bytes');
                        });
                      } else {
                        print('❌ Тасвир интихоб нашуд (result is null)');
                      }
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: themeState.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: imageBytes != null ? themeState.primaryColor : themeState.borderColor,
                          width: imageBytes != null ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeState.primaryColor.withOpacity(imageBytes != null ? 0.2 : 0),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                imageBytes!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: themeState.primaryColor.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 50,
                                    color: themeState.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Выбрать фото',
                                  style: TextStyle(
                                    color: themeState.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Name field - SECOND
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Название',
                      style: TextStyle(
                        color: themeState.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: themeState.textColor),
                    decoration: InputDecoration(
                      hintText: 'Введите название категории',
                      hintStyle: TextStyle(color: themeState.secondaryTextColor),
                      filled: true,
                      fillColor: themeState.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeState.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeState.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeState.primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    color: themeState.secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
              ),
              // Save button
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите название категории'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Save category to Google Sheets via BLoC
                  final categoryName = nameController.text.trim();
                  
                  context.read<CategoryBloc>().add(
                    CategoryAddRequested(
                      name: categoryName,
                      imageBase64: selectedImageBase64,
                    ),
                  );
                  
                  Navigator.pop(dialogContext);
                  
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Сохранение "$categoryName"...'),
                        ],
                      ),
                      backgroundColor: themeState.primaryColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeState.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Edit category dialog
  void _showEditCategoryDialog(BuildContext context, ThemeState themeState, CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    String? selectedImageBase64 = category.imageBase64;
    Uint8List? imageBytes = category.imageBase64 != null 
        ? base64Decode(category.imageBase64!) 
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: themeState.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Редактировать',
                  style: TextStyle(
                    color: themeState.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image picker
                  Text(
                    'Изображение',
                    style: TextStyle(
                      color: themeState.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final result = await _pickCategoryImage();
                      if (result != null) {
                        setState(() {
                          imageBytes = result['bytes'];
                          selectedImageBase64 = result['base64'];
                        });
                      }
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: themeState.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: imageBytes != null ? Colors.blue : themeState.borderColor,
                          width: imageBytes != null ? 3 : 1,
                        ),
                      ),
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                imageBytes!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 48,
                                  color: themeState.secondaryTextColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+ фото',
                                  style: TextStyle(
                                    color: themeState.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Category name
                  Text(
                    'Название категории',
                    style: TextStyle(
                      color: themeState.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: themeState.textColor),
                    decoration: InputDecoration(
                      hintText: 'Введите название категории',
                      hintStyle: TextStyle(color: themeState.secondaryTextColor),
                      filled: true,
                      fillColor: themeState.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  this.setState(() {
                    _selectedCategoryForEdit = null;
                  });
                },
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    color: themeState.secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите название категории'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Update category via BLoC
                  final categoryName = nameController.text.trim();
                  
                  context.read<CategoryBloc>().add(
                    CategoryUpdateRequested(
                      id: category.id,
                      name: categoryName,
                      imageBase64: selectedImageBase64,
                    ),
                  );
                  
                  Navigator.pop(dialogContext);
                  this.setState(() {
                    _selectedCategoryForEdit = null;
                  });
                  
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Обновление "$categoryName"...'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Delete confirmation dialog
  void _showDeleteConfirmDialog(BuildContext context, ThemeState themeState, CategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeState.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Удалить категорию?',
                style: TextStyle(
                  color: themeState.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Вы действительно хотите удалить категорию "${category.name}"?\n\nЭто действие нельзя отменить.',
          style: TextStyle(
            color: themeState.secondaryTextColor,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _selectedCategoryForEdit = null;
              });
            },
            child: Text(
              'Отмена',
              style: TextStyle(
                color: themeState.secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete category via BLoC
              context.read<CategoryBloc>().add(
                CategoryDeleteRequested(category.id),
              );
              
              Navigator.pop(dialogContext);
              setState(() {
                _selectedCategoryForEdit = null;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Категория "${category.name}" удалена'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Удалить',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build product card
  Widget _buildProductCard(ProductModel product, ThemeState themeState, bool isDesktop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: themeState.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  // Image
                  if (product.imageBase64 != null && product.imageBase64!.isNotEmpty)
                    RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.memory(
                          base64Decode(product.imageBase64!),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 50,
                                color: themeState.secondaryTextColor,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 50,
                        color: themeState.secondaryTextColor,
                      ),
                    ),
                  
                  // Stock badge (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.stock > 0 
                            ? themeState.primaryColor 
                            : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.stock.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Product info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: TextStyle(
                      color: themeState.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        '${product.salePrice.toStringAsFixed(2)} с',
                        style: TextStyle(
                          color: themeState.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Unit
                      if (product.unit != null && product.unit!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeState.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.unit!,
                            style: TextStyle(
                              color: themeState.secondaryTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _pickCategoryImage() async {
    try {
      Uint8List? imageBytes;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: use file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: false,
        );

        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          imageBytes = await file.readAsBytes();
        }
      } else {
        // Mobile: use image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          imageBytes = await pickedFile.readAsBytes();
        }
      }

      if (imageBytes == null) return null;

      // Resize and compress image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('❌ Тасвирро decode карда натавонист');
        return null;
      }

      print('📐 Андозаи аслӣ: ${image.width}x${image.height}');

      // Calculate target dimensions while maintaining aspect ratio
      img.Image resized;
      if (image.width > image.height) {
        // Landscape or square
        resized = img.copyResize(image, width: 500);
      } else {
        // Portrait
        resized = img.copyResize(image, height: 500);
      }
      
      print('📐 Андозаи нав: ${resized.width}x${resized.height}');
      
      // Compress to JPEG with quality 60
      final compressed = img.encodeJpg(resized, quality: 60);
      
      // Convert to base64
      final base64String = base64Encode(compressed);

      print('✅ Тасвир тайёр: ${compressed.length} bytes, base64: ${base64String.length} chars');

      return {
        'bytes': Uint8List.fromList(compressed),
        'base64': base64String,
      };
    } catch (e) {
      print('❌ Хатогӣ дар интихоби тасвир: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                
                return GestureDetector(
                  onTap: () {
                    // Close edit mode when tapping anywhere
                    if (_selectedCategoryForEdit != null) {
                      setState(() {
                        _selectedCategoryForEdit = null;
                      });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 30 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Search bar with barcode button inside
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: themeState.cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: themeState.borderColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Search icon
                            Padding(
                              padding: const EdgeInsets.only(left: 15, right: 10),
                              child: Icon(
                                Icons.search,
                                color: themeState.secondaryTextColor,
                                size: 24,
                              ),
                            ),
                            // Text field
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: themeState.textColor),
                                decoration: InputDecoration(
                                  hintText: 'Поиск товара...',
                                  hintStyle: TextStyle(color: themeState.secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                            // Barcode button inside
                            Container(
                              margin: const EdgeInsets.all(5),
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: themeState.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  // TODO: Implement barcode scanner
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Сканер баркода: В разработке'),
                                      backgroundColor: themeState.primaryColor,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Categories section
                      BlocConsumer<CategoryBloc, CategoryState>(
                        listener: (context, categoryState) {
                          // Show error if any
                          if (categoryState.error != null && categoryState.error!.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(categoryState.error!),
                                backgroundColor: Colors.red,
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
                              
                              // Horizontal scrolling categories
                              SizedBox(
                                height: isDesktop ? 140 : 120,
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
                                    final showEditButtons = _selectedCategoryForEdit == category.id;
                                    
                                    return _buildCategoryCard(
                                      category: category,
                                      isSelected: isSelected,
                                      themeState: themeState,
                                      isDesktop: isDesktop,
                                      showEditButtons: showEditButtons,
                                      onTap: () {
                                        if (_selectedCategoryForEdit == category.id) {
                                          // If edit mode, cancel it
                                          setState(() {
                                            _selectedCategoryForEdit = null;
                                          });
                                        } else {
                                          // Normal category selection
                                          context.read<CategoryBloc>().add(
                                            CategorySelected(category.id),
                                          );
                                        }
                                      },
                                      onLongPress: () {
                                        // Toggle edit mode
                                        setState(() {
                                          if (_selectedCategoryForEdit == category.id) {
                                            _selectedCategoryForEdit = null;
                                          } else {
                                            _selectedCategoryForEdit = category.id;
                                          }
                                        });
                                      },
                                      onEdit: () {
                                        _showEditCategoryDialog(context, themeState, category);
                                      },
                                      onDelete: () {
                                        _showDeleteConfirmDialog(context, themeState, category);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Products area
                      Expanded(
                        child: BlocBuilder<ProductBloc, ProductState>(
                          builder: (context, productState) {
                            return Column(
                              children: [
                                // Products header with buttons
                                Row(
                                  children: [
                                    Text(
                                      'Продукты',
                                      style: TextStyle(
                                        color: themeState.textColor,
                                        fontSize: isDesktop ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Add product button
                                    IconButton(
                                      onPressed: () {
                                        // TODO: Open add product dialog
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Добавить продукт - в разработке'),
                                            backgroundColor: themeState.primaryColor,
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.add_circle, color: themeState.primaryColor),
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
                                            ? themeState.primaryColor 
                                            : themeState.secondaryTextColor,
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
                                        color: themeState.secondaryTextColor,
                                      ),
                                      tooltip: productState.viewMode == ProductViewMode.grid
                                          ? 'Список'
                                          : 'Сетка',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                
                                // Products list/grid
                                Expanded(
                                  child: productState.isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : productState.filteredProducts.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.shopping_bag_outlined,
                                                    size: 80,
                                                    color: themeState.secondaryTextColor,
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Text(
                                                    'Продуктов пока нет',
                                                    style: TextStyle(
                                                      color: themeState.textColor,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    'Нажмите + чтобы добавить',
                                                    style: TextStyle(
                                                      color: themeState.secondaryTextColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : GridView.builder(
                                              padding: const EdgeInsets.all(8),
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: isDesktop ? 4 : 2,
                                                crossAxisSpacing: 12,
                                                mainAxisSpacing: 12,
                                                childAspectRatio: 0.75,
                                              ),
                                              itemCount: productState.filteredProducts.length,
                                              itemBuilder: (context, index) {
                                                final product = productState.filteredProducts[index];
                                                return _buildProductCard(product, themeState, isDesktop);
                                              },
                                            ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
