import 'package:gsheets/gsheets.dart';
import '../models/category_model.dart';
import '../services/hive_service.dart';
import '../services/gsheets_service.dart';

class CategoryRepository {
  static Worksheet? _worksheet;

  // Initialize - using shared GsheetsService
  static Future<void> init() async {
    try {
      _worksheet = await GsheetsService.getOrCreateWorksheet(
        'categories',
        ['id', 'name', 'image', 'productCount', 'position'],
      );
      print('✅ CategoryRepository инициализатсия шуд');
    } catch (e) {
      print('❌ Хатои CategoryRepository.init(): $e');
    }
  }

  // Get all categories from Google Sheets
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty || allRows.length < 2) {
        return [];
      }

      final headers = allRows.first;
      final categories = <CategoryModel>[];

      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        final map = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        if (map['id'] != null && map['id'].toString().isNotEmpty) {
          categories.add(CategoryModel.fromMap(map));
        }
      }

      // Sort by position
      categories.sort((a, b) => a.position.compareTo(b.position));

      // Cache in Hive
      await HiveService.cacheCategories(categories);

      print('✅ ${categories.length} категория аз Google Sheets гирифта шуд');
      return categories;
    } catch (e) {
      print('❌ Хатои getAllCategories(): $e');
      // Load from Hive cache if Google Sheets fails
      return await HiveService.getCachedCategories();
    }
  }

  // Add new category to Google Sheets
  Future<bool> addCategory(CategoryModel category) async {
    try {
      if (_worksheet == null) {
        await init();
      }

      await _worksheet!.values.appendRow([
        category.id,
        category.name,
        category.imageBase64 ?? '',
        category.productCount,
        category.position,
      ]);

      print('✅ Категория "${category.name}" илова шуд');
      return true;
    } catch (e) {
      print('❌ Хатои addCategory(): $e');
      return false;
    }
  }

  // Update category in Google Sheets
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty) return false;

      // Find row by id
      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty && row[0] == category.id.toString()) {
          // Delete old row and insert new one
          final rowIndex = i + 1; // Row index is 1-based
          await _worksheet!.deleteRow(rowIndex);
          await _worksheet!.values.insertRow(
            rowIndex,
            [
              category.id,
              category.name,
              category.imageBase64 ?? '',
              category.productCount,
              category.position,
            ],
          );
          print('✅ Категория "${category.name}" навсозӣ шуд');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Хатои updateCategory(): $e');
      return false;
    }
  }

  // Delete category from Google Sheets
  Future<bool> deleteCategory(int categoryId) async {
    try {
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty) return false;

      // Find and delete row by id
      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty && row[0] == categoryId.toString()) {
          await _worksheet!.deleteRow(i + 1);
          print('✅ Категория бо ID $categoryId нест шуд');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Хатои deleteCategory(): $e');
      return false;
    }
  }
}

