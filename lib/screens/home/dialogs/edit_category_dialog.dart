import 'dart:convert';
import '../../../utils/base64_helper.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../bloc/category/category_bloc.dart';
import '../../../bloc/category/category_event.dart';
import '../../../models/category_model.dart';
import '../../../services/image_helper.dart';

class EditCategoryDialog {
  static Future<void> show(
    BuildContext context,
    ThemeState themeState,
    CategoryModel category,
  ) async {
    final nameController = TextEditingController(text: category.name);
    String? selectedImageBase64 = category.imageBase64;
    Uint8List? imageBytes = category.imageBase64 != null 
        ? safeBase64Decode(category.imageBase64!) 
        : null;

    return showDialog(
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
                  'Изменить категорию',
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
                      final result = await ImageHelper.pickAndCompressImage();
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
                  
                  // Name field
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

                  Navigator.pop(dialogContext);

                  // Dispatch update event
                  context.read<CategoryBloc>().add(
                    CategoryUpdateRequested(
                      id: category.id,
                      name: nameController.text.trim(),
                      imageBase64: selectedImageBase64,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
}

