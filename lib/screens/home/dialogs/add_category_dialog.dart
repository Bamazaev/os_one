import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../bloc/category/category_bloc.dart';
import '../../../bloc/category/category_event.dart';
import '../../../services/image_helper.dart';

class AddCategoryDialog {
  static Future<void> show(BuildContext context, ThemeState themeState) async {
    final nameController = TextEditingController();
    String? selectedImageBase64;
    Uint8List? imageBytes;

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
                      final result = await ImageHelper.pickAndCompressImage();
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
                          Text('Добавление категории "$categoryName"...'),
                        ],
                      ),
                      duration: const Duration(seconds: 5),
                      backgroundColor: Colors.blue,
                    ),
                  );

                  // Dispatch CategoryAddRequested event
                  context.read<CategoryBloc>().add(
                    CategoryAddRequested(
                      name: categoryName,
                      imageBase64: selectedImageBase64,
                    ),
                  );

                  // Success message will be shown by BLoC listener
                  print('🟢 BLoC event dispatched: CategoryAddRequested($categoryName)');
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
}

