import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../bloc/category/category_bloc.dart';
import '../../../bloc/category/category_event.dart';
import '../../../models/category_model.dart';

class DeleteCategoryDialog {
  static Future<void> show(
    BuildContext context,
    ThemeState themeState,
    CategoryModel category,
  ) async {
    return showDialog(
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
                Icons.delete_forever,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Удалить категорию?',
              style: TextStyle(
                color: themeState.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Вы уверены, что хотите удалить категорию "${category.name}"?\n\nЭто действие нельзя отменить.',
          style: TextStyle(
            color: themeState.textColor,
            fontSize: 16,
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
          // Delete button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Dispatch delete event
              context.read<CategoryBloc>().add(
                CategoryDeleteRequested(category.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Удалить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

