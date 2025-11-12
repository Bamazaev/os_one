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
                  
                  // Close dialog first
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
                      backgroundColor: themeState.primaryColor.withOpacity(0.8),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  
                  // Dispatch event
                  context.read<CategoryBloc>().add(
                    CategoryAddRequested(
                      name: categoryName,
                      imageBase64: selectedImageBase64,
                    ),
                  );
                  
                  // Wait for the category to be added and show success message
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '✅ Категория "$categoryName" илова шуд!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: themeState.primaryColor,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
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
                  
                  // Close dialog first
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
                      backgroundColor: themeState.primaryColor.withOpacity(0.8),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  
                  // Dispatch event
                  context.read<CategoryBloc>().add(
                    CategoryUpdateRequested(
                      id: category.id,
                      name: categoryName,
                      imageBase64: selectedImageBase64,
                    ),
                  );
                  
                  // Wait for the category to be updated and show success message
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '✅ Категория "$categoryName" навсозӣ шуд!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: themeState.primaryColor,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeState.primaryColor,
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
    final bool isExpired = product.expireAt != null && 
      DateTime.tryParse(product.expireAt!) != null &&
      DateTime.parse(product.expireAt!).isBefore(DateTime.now());
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 25 : 20),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: isDesktop ? 20 : 15,
              offset: Offset(0, isDesktop ? 8 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Просмотр: ${product.name}'),
                  backgroundColor: themeState.primaryColor,
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
            onLongPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Редактировать: ${product.name}'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
            child: Stack(
              children: [
                // Full-screen product image
                RepaintBoundary(
                  child: product.imageBase64 != null && product.imageBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(product.imageBase64!),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
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
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: isDesktop ? 60 : 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                
                // Dark gradient overlay at bottom for text readability
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
                
                // Price badges (top right) - Purchase and Sale prices
                Positioned(
                  top: isDesktop ? 10 : 6,
                  right: isDesktop ? 10 : 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Sale price (green) - только для клиента
                      Container(
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
                      // Purchase price removed - клиент набинад
                    ],
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
                        // Stock and sold badges (center)
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
                                      ? product.unit! 
                                      : 'КГ',
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
                        
                        // Product name (medium, bold)
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
                        
                        // Product description (small, light)
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
                
                // Expired warning banner (if applicable)
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show add product dialog
  Future<void> _showAddProductDialog(BuildContext context, ThemeState themeState) async {
    final nameController = TextEditingController();
    final barcodeController = TextEditingController();
    final descriptionController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final purchasePriceController = TextEditingController(text: '0');
    final salePriceController = TextEditingController(text: '0');
    
    String? selectedImageBase64;
    Uint8List? selectedImageBytes;
    int? selectedCategoryId;
    DateTime? selectedExpireDate;
    String? selectedUnit;
    bool isFavorite = false;
    
    // Unit options
    final List<Map<String, String>> unitOptions = [
      {'value': 'КГ', 'label': 'КГ (килограмм)'},
      {'value': 'Л', 'label': 'Л (литр)'},
      {'value': 'М', 'label': 'М (метр)'},
      {'value': 'ШТ', 'label': 'ШТ (штука)'},
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: themeState.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Добавить продукт',
              style: TextStyle(
                color: themeState.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker - FIRST
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await _pickProductImage();
                          if (result != null) {
                            setState(() {
                              selectedImageBase64 = result['base64'];
                              selectedImageBytes = result['bytes'];
                            });
                          }
                        },
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(
                                  selectedImageBytes!,
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: themeState.surfaceColor,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: themeState.primaryColor.withOpacity(0.5),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color: themeState.primaryColor,
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
                    ),
                    const SizedBox(height: 25),

                    // Name field
                    _buildTextField(
                      controller: nameController,
                      label: 'Название *',
                      hint: 'Введите название продукта',
                      themeState: themeState,
                    ),
                    const SizedBox(height: 15),

                    // Barcode field
                    _buildTextField(
                      controller: barcodeController,
                      label: 'Баркод',
                      hint: 'Введите баркод',
                      themeState: themeState,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),

                    // Category dropdown
                    Text(
                      'Категория *',
                      style: TextStyle(
                        color: themeState.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, categoryState) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: themeState.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: themeState.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedCategoryId,
                              isExpanded: true,
                              hint: Text(
                                'Выберите категорию',
                                style: TextStyle(color: themeState.secondaryTextColor),
                              ),
                              dropdownColor: themeState.surfaceColor,
                              style: TextStyle(color: themeState.textColor),
                              items: categoryState.categories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategoryId = value;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Description field
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Описание',
                      hint: 'Введите описание',
                      themeState: themeState,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),

                    // Sale price and stock row (SWAPPED ORDER)
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: salePriceController,
                            label: 'Цена продажи *',
                            hint: '0.00',
                            themeState: themeState,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: stockController,
                            label: 'Склад *',
                            hint: '0',
                            themeState: themeState,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Purchase price and unit row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: purchasePriceController,
                            label: 'Цена покупки *',
                            hint: '0.00',
                            themeState: themeState,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Unit dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Единица',
                                style: TextStyle(
                                  color: themeState.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: themeState.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: themeState.borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedUnit,
                                    isExpanded: true,
                                    hint: Text(
                                      'Выберите',
                                      style: TextStyle(color: themeState.secondaryTextColor),
                                    ),
                                    dropdownColor: themeState.surfaceColor,
                                    style: TextStyle(color: themeState.textColor),
                                    items: unitOptions.map((unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit['value'],
                                        child: Text(unit['label']!),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedUnit = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Expire date picker
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: themeState.primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            selectedExpireDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: themeState.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: themeState.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: themeState.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedExpireDate != null
                                  ? '${selectedExpireDate!.day}.${selectedExpireDate!.month}.${selectedExpireDate!.year}'
                                  : 'Срок годности (опционально)',
                              style: TextStyle(
                                color: selectedExpireDate != null
                                    ? themeState.textColor
                                    : themeState.secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Favorite checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isFavorite,
                          activeColor: themeState.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              isFavorite = value ?? false;
                            });
                          },
                        ),
                        Text(
                          'Избранное',
                          style: TextStyle(
                            color: themeState.textColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  // Validation
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите название продукта'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Выберите категорию'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Generate ID and position
                  final productId = DateTime.now().millisecondsSinceEpoch % 100000000;
                  final position = DateTime.now().millisecondsSinceEpoch % 100000;

                  // Create product
                  final product = ProductModel(
                    id: productId,
                    barcode: barcodeController.text.trim().isEmpty 
                        ? '' 
                        : barcodeController.text.trim(),
                    categoryId: selectedCategoryId!,
                    name: nameController.text.trim(),
                    imageBase64: selectedImageBase64,
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                    stock: double.tryParse(stockController.text) ?? 0.0,
                    stockSold: 0.0,
                    purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                    salePrice: double.tryParse(salePriceController.text) ?? 0.0,
                    isFavorite: isFavorite,
                    position: position,
                    expireAt: selectedExpireDate?.toIso8601String(),
                    unit: selectedUnit,
                  );

                  // Close dialog first
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
                          const SizedBox(width: 16),
                          Text('Сохранение "${product.name}"...'),
                        ],
                      ),
                      backgroundColor: themeState.primaryColor.withOpacity(0.8),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  // Dispatch event
                  context.read<ProductBloc>().add(ProductAddRequested(product));

                  // Wait for the product to be added and show success message
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '✅ Продукт "${product.name}" илова шуд!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: themeState.primaryColor,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeState.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    color: Colors.white,
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

  // Helper: Build text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeState themeState,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeState.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: themeState.textColor),
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }

  // Pick product image
  Future<Map<String, dynamic>?> _pickProductImage() async {
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
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 70,
        );

        if (pickedFile != null) {
          imageBytes = await pickedFile.readAsBytes();
        }
      }

      if (imageBytes == null) return null;

      // Resize and compress image HEAVILY for Google Sheets
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('❌ Тасвирро decode карда натавонист');
        return null;
      }

      print('📐 Андозаи аслӣ: ${image.width}x${image.height}');

      // Resize to max 400px on longest side (SMALLER for Google Sheets limit)
      img.Image resized;
      if (image.width > image.height) {
        // Landscape or square
        resized = img.copyResize(image, width: 400);
      } else {
        // Portrait
        resized = img.copyResize(image, height: 400);
      }

      print('📐 Андозаи нав: ${resized.width}x${resized.height}');

      // Compress to JPEG with lower quality (70%) for Google Sheets
      final compressedBytes = img.encodeJpg(resized, quality: 70);
      final base64String = base64Encode(compressedBytes);

      print('📊 Андозаи Base64: ${(base64String.length / 1024).toStringAsFixed(2)} KB');
      print('📊 Символҳо: ${base64String.length} (макс: 50000)');

      // Check if still too large
      if (base64String.length > 48000) {
        print('⚠️ Тасвир то ҳол калон аст, майдатар мекунем...');
        
        // Further resize to 300px if still too large
        img.Image smallerResized;
        if (resized.width > resized.height) {
          smallerResized = img.copyResize(resized, width: 300);
        } else {
          smallerResized = img.copyResize(resized, height: 300);
        }
        
        final smallerBytes = img.encodeJpg(smallerResized, quality: 65);
        final smallerBase64 = base64Encode(smallerBytes);
        
        print('📊 Андозаи нави Base64: ${(smallerBase64.length / 1024).toStringAsFixed(2)} KB');
        print('📊 Символҳо: ${smallerBase64.length}');
        
        return {
          'base64': smallerBase64,
          'bytes': Uint8List.fromList(smallerBytes),
        };
      }

      return {
        'base64': base64String,
        'bytes': Uint8List.fromList(compressedBytes),
      };
    } catch (e) {
      print('❌ Хатогӣ дар _pickProductImage: $e');
      return null;
    }
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
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 70,
        );

        if (pickedFile != null) {
          imageBytes = await pickedFile.readAsBytes();
        }
      }

      if (imageBytes == null) return null;

      // Resize and compress image HEAVILY for Google Sheets
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('❌ Тасвирро decode карда натавонист');
        return null;
      }

      print('📐 Андозаи аслӣ: ${image.width}x${image.height}');

      // Resize to max 400px on longest side (SMALLER for Google Sheets limit)
      img.Image resized;
      if (image.width > image.height) {
        // Landscape or square
        resized = img.copyResize(image, width: 400);
      } else {
        // Portrait
        resized = img.copyResize(image, height: 400);
      }
      
      print('📐 Андозаи нав: ${resized.width}x${resized.height}');
      
      // Compress to JPEG with lower quality (70%) for Google Sheets
      final compressed = img.encodeJpg(resized, quality: 70);
      
      // Convert to base64
      final base64String = base64Encode(compressed);

      print('📊 Андозаи Base64: ${(base64String.length / 1024).toStringAsFixed(2)} KB');
      print('📊 Символҳо: ${base64String.length} (макс: 50000)');

      // Check if still too large
      if (base64String.length > 48000) {
        print('⚠️ Тасвир то ҳол калон аст, майдатар мекунем...');
        
        // Further resize to 300px if still too large
        img.Image smallerResized;
        if (resized.width > resized.height) {
          smallerResized = img.copyResize(resized, width: 300);
        } else {
          smallerResized = img.copyResize(resized, height: 300);
        }
        
        final smallerBytes = img.encodeJpg(smallerResized, quality: 65);
        final smallerBase64 = base64Encode(smallerBytes);
        
        print('📊 Андозаи нави Base64: ${(smallerBase64.length / 1024).toStringAsFixed(2)} KB');
        print('📊 Символҳо: ${smallerBase64.length}');
        
        return {
          'base64': smallerBase64,
          'bytes': Uint8List.fromList(smallerBytes),
        };
      }

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
                        child: BlocConsumer<ProductBloc, ProductState>(
                          listener: (context, productState) {
                            // Show success message when product is added
                            if (productState.products.isNotEmpty && !productState.isLoading && productState.error == null) {
                              // Product added successfully - show green snackbar
                              // (only if we're not initially loading)
                            }
                            
                            // Show error if any
                            if (productState.error != null && productState.error!.isNotEmpty) {
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
                                        color: themeState.textColor,
                                        fontSize: isDesktop ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Add product button
                                    IconButton(
                                      onPressed: () => _showAddProductDialog(context, themeState),
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
                                                childAspectRatio: isDesktop ? 0.85 : 1.0, // Desktop: калонтар (0.85), Mobile: чоркунча (1.0)
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
