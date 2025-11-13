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

  // Get all categories from Google Sheets (force from network, skip cache)
  Future<List<CategoryModel>> getAllCategoriesForceRefresh() async {
    try {
      // Clear cache to force reload from Google Sheets
      await HiveService.clearCategoriesCache();
      
      // Load from Google Sheets
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty || allRows.length < 2) {
        return [];
      }

      final headers = allRows.first;
      print('📋 Заголовки категорий в Google Sheets: $headers');
      final categories = <CategoryModel>[];

      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        final map = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        if (map['id'] != null && map['id'].toString().isNotEmpty) {
          final category = CategoryModel.fromMap(map);
          categories.add(category);
        }
      }

      // Sort by position
      categories.sort((a, b) => a.position.compareTo(b.position));

      // Cache in Hive
      await HiveService.cacheCategories(categories);

      print('✅ ${categories.length} категория аз Google Sheets гирифта шуд (force refresh)');
      return categories;
    } catch (e) {
      print('⚠️ Ошибка сети при загрузке категорий: $e');
      // Return empty list on error (don't use cache on force refresh)
      return [];
    }
  }

  // Get all categories from Google Sheets
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      // Try to load from cache first (for offline mode)
      final cachedCategories = await HiveService.getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        print('✅ ${cachedCategories.length} категория аз cache гирифта шуд');
        // Try to load from network in background, but return cache immediately
        _loadCategoriesFromNetwork().catchError((e) {
          print('⚠️ Ошибка загрузки категорий из сети (офлайн режим): $e');
        });
        return cachedCategories;
      }

      // Load from Google Sheets if cache is empty
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty || allRows.length < 2) {
        // Return cache if available, even if empty
        return await HiveService.getCachedCategories();
      }

      final headers = allRows.first;
      print('📋 Заголовки категорий в Google Sheets: $headers');
      final categories = <CategoryModel>[];

      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        final map = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        if (map['id'] != null && map['id'].toString().isNotEmpty) {
          final category = CategoryModel.fromMap(map);
          categories.add(category);
          // Debug first category to see id
          if (i == 1) {
            print('🔍 Первая категория: "${category.name}", id: ${category.id}');
          }
        }
      }

      // Sort by position
      categories.sort((a, b) => a.position.compareTo(b.position));

      // Cache in Hive
      await HiveService.cacheCategories(categories);

      print('✅ ${categories.length} категория аз Google Sheets гирифта шуд');
      return categories;
    } catch (e) {
      print('⚠️ Ошибка сети при загрузке категорий: $e');
      // Load from Hive cache if Google Sheets fails (offline mode)
      final cachedCategories = await HiveService.getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        print('📦 Используем кэш категорий (офлайн режим): ${cachedCategories.length} категорий');
      }
      return cachedCategories;
    }
  }

  // Load categories from network (background task)
  Future<void> _loadCategoriesFromNetwork() async {
    try {
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty || allRows.length < 2) {
        return;
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
          final category = CategoryModel.fromMap(map);
          categories.add(category);
        }
      }

      categories.sort((a, b) => a.position.compareTo(b.position));
      await HiveService.cacheCategories(categories);
      print('✅ Категории обновлены из сети в фоне');
    } catch (e) {
      print('⚠️ Ошибка фонового обновления категорий: $e');
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
      print('⚠️ Ошибка сети при добавлении категории: $e');
      // Save to offline queue
      await HiveService.addPendingOperation('add_category', category.toMap());
      // Also save to cache immediately for offline display
      final cachedCategories = await HiveService.getCachedCategories();
      cachedCategories.add(category);
      await HiveService.cacheCategories(cachedCategories);
      print('📝 Категория сохранена в офлайн очередь и кэш');
      return false; // Return false to indicate it wasn't saved to Google Sheets yet
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

