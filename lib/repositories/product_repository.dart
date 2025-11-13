import 'package:gsheets/gsheets.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/hive_service.dart';
import '../services/gsheets_service.dart';
import 'category_repository.dart';

// Result class to indicate if data came from cache
class ProductLoadResult {
  final List<ProductModel> products;
  final bool fromCache;

  ProductLoadResult({
    required this.products,
    required this.fromCache,
  });
}

class ProductRepository {
  static Worksheet? _worksheet;

  // Initialize - using shared GsheetsService
  static Future<void> init() async {
    try {
      _worksheet = await GsheetsService.getOrCreateWorksheet(
        'products',
        [
          'id',
          'barcode',
          'categoryid',
          'name',
          'image',
          'description',
          'stock',
          'stock_furuhtashud',
          'narhiOmadagish',
          'narhifurush',
          'isFavorite',
          'position',
          'expireAt',
          'piece',
          'unit',
        ],
      );
      print('✅ ProductRepository initialized');
    } catch (e) {
      print('❌ Хатои ProductRepository.init(): $e');
    }
  }

  // Get all products with cache info (force from network, skip cache)
  Future<ProductLoadResult> getAllProductsWithCacheInfoForceRefresh() async {
    try {
      // Clear cache to force reload from Google Sheets
      await HiveService.clearProductsCache();
      
      // Load from Google Sheets
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty || allRows.length < 2) {
        return ProductLoadResult(products: [], fromCache: false);
      }

      final headers = allRows.first;
      print('📋 Заголовки продуктов в Google Sheets: $headers');
      final products = <ProductModel>[];

      // Get categories to match by name if needed
      final categoryRepo = CategoryRepository();
      final categories = await categoryRepo.getAllCategories();
      print('📋 Загружено ${categories.length} категорий для сопоставления');

      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        final map = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        // Check if row has ID (more flexible check)
        final idValue = map['id'];
        if (idValue != null && idValue.toString().trim().isNotEmpty) {
          // Try to resolve categoryId - might be name or ID
          final categoryIdValue = map['categoryid'] ?? map['categoryId'] ?? map['CategoryId'];
          int? resolvedCategoryId;
          
          if (categoryIdValue != null) {
            final categoryIdStr = categoryIdValue.toString().trim();
            // Try to parse as integer first
            resolvedCategoryId = int.tryParse(categoryIdStr);
            
            // If not a number, try to find by category name
            if (resolvedCategoryId == null || resolvedCategoryId == 0) {
              final matchingCategory = categories.firstWhere(
                (cat) => cat.name.toLowerCase().trim() == categoryIdStr.toLowerCase().trim(),
                orElse: () => CategoryModel(id: 0, name: ''),
              );
              if (matchingCategory.id != 0) {
                resolvedCategoryId = matchingCategory.id;
                print('✅ Найдена категория по имени: "$categoryIdStr" → ID: ${matchingCategory.id}');
              } else {
                print('⚠️ Категория не найдена по имени: "$categoryIdStr"');
              }
            }
          }
          
          // Update map with resolved categoryId
          if (resolvedCategoryId != null) {
            map['categoryid'] = resolvedCategoryId;
          }
          
          try {
            final product = ProductModel.fromMap(map);
            products.add(product);
            
            // Debug all products, especially Pepsi
            final productName = product.name.toLowerCase();
            if (productName.contains('pepsi') || i <= 3 || i == allRows.length - 1) {
              print('🔍 Продукт #$i: "${product.name}" (ID: ${product.id}), categoryId: ${product.categoryId}, barcode: ${product.barcode}');
            }
          } catch (e) {
            print('❌ Ошибка парсинга продукта в строке $i: $e');
            print('   Данные: id=${map['id']}, name=${map['name']}, categoryid=${map['categoryid']}');
          }
        } else {
          // Log rows without ID for debugging
          final nameValue = map['name']?.toString() ?? '';
          if (nameValue.isNotEmpty && nameValue.toLowerCase().contains('pepsi')) {
            print('⚠️ Найдена строка с "Pepsi", но без ID: $map');
          }
        }
      }

      // Sort by position
      products.sort((a, b) => a.position.compareTo(b.position));

      // Debug: Check if Pepsi is in the list
      final pepsiProducts = products.where((p) => p.name.toLowerCase().contains('pepsi')).toList();
      if (pepsiProducts.isNotEmpty) {
        print('✅ Найдено ${pepsiProducts.length} продукт(ов) с "Pepsi":');
        for (var p in pepsiProducts) {
          print('   - "${p.name}" (ID: ${p.id}, categoryId: ${p.categoryId}, barcode: ${p.barcode})');
        }
      } else {
        print('⚠️ Продукт "Pepsi" не найден в загруженных продуктах');
        print('   Всего загружено: ${products.length} продуктов');
        if (products.isNotEmpty) {
          print('   Примеры названий: ${products.take(5).map((p) => '"${p.name}"').join(", ")}');
        }
      }

      // Cache in Hive
      await HiveService.cacheProducts(products);

      print('✅ ${products.length} продукт аз Google Sheets гирифта шуд (force refresh)');
      return ProductLoadResult(products: products, fromCache: false);
    } catch (e) {
      print('❌ Критическая ошибка getAllProductsForceRefresh(): $e');
      return ProductLoadResult(products: [], fromCache: false);
    }
  }

  // Get all products with cache info (for BLoC to know if loading indicator needed)
  Future<ProductLoadResult> getAllProductsWithCacheInfo() async {
    try {
      // Try to load from cache first
      final cachedProducts = await HiveService.getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        print('✅ ${cachedProducts.length} продукт аз cache гирифта шуд');
        
        // Get categories to resolve categoryId if needed (for cached products with category names)
        final categoryRepo = CategoryRepository();
        final categories = await categoryRepo.getAllCategories();
        
        // Process cached products and resolve categoryId if needed
        int productsWithZeroCategoryId = 0;
        final products = cachedProducts.map((map) {
          // Check if categoryId is 0 or might be a category name
          final categoryIdValue = map['categoryid'] ?? map['categoryId'];
          int? resolvedCategoryId;
          
          if (categoryIdValue != null) {
            final categoryIdStr = categoryIdValue.toString().trim();
            resolvedCategoryId = int.tryParse(categoryIdStr);
            
            // If not a number or is 0, try to find by category name
            if (resolvedCategoryId == null || resolvedCategoryId == 0) {
              final matchingCategory = categories.firstWhere(
                (cat) => cat.name.toLowerCase().trim() == categoryIdStr.toLowerCase().trim(),
                orElse: () => CategoryModel(id: 0, name: ''),
              );
              if (matchingCategory.id != 0) {
                resolvedCategoryId = matchingCategory.id;
                map['categoryid'] = resolvedCategoryId; // Update map for future use
              } else {
                productsWithZeroCategoryId++;
              }
            }
          } else {
            productsWithZeroCategoryId++;
          }
          
          return ProductModel.fromMap(map);
        }).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        
        // If many products have categoryId = 0, clear cache and reload from Google Sheets
        if (productsWithZeroCategoryId > products.length * 0.5) {
          print('⚠️ Много продуктов с categoryId = 0, очищаем кэш и перезагружаем из Google Sheets');
          await HiveService.clearProductsCache();
          // Continue to load from Google Sheets below
        } else {
          return ProductLoadResult(products: products, fromCache: true);
        }
      }

      // Load from Google Sheets if cache is empty
      try {
        if (_worksheet == null) {
          await init();
        }

        final allRows = await _worksheet!.values.allRows();
        if (allRows.isEmpty || allRows.length < 2) {
          return ProductLoadResult(products: [], fromCache: false);
        }

        final headers = allRows.first;
        print('📋 Заголовки продуктов в Google Sheets: $headers');
        final products = <ProductModel>[];

        // Get categories to match by name if needed
        final categoryRepo = CategoryRepository();
        final categories = await categoryRepo.getAllCategories();
        print('📋 Загружено ${categories.length} категорий для сопоставления');

        for (int i = 1; i < allRows.length; i++) {
          final row = allRows[i];
          final map = <String, dynamic>{};

          for (int j = 0; j < headers.length && j < row.length; j++) {
            map[headers[j]] = row[j];
          }

          // Check if row has ID (more flexible check)
          final idValue = map['id'];
          if (idValue != null && idValue.toString().trim().isNotEmpty) {
            // Try to resolve categoryId - might be name or ID
            final categoryIdValue = map['categoryid'] ?? map['categoryId'] ?? map['CategoryId'];
            int? resolvedCategoryId;
            
            if (categoryIdValue != null) {
              final categoryIdStr = categoryIdValue.toString().trim();
              // Try to parse as integer first
              resolvedCategoryId = int.tryParse(categoryIdStr);
              
              // If not a number, try to find by category name
              if (resolvedCategoryId == null || resolvedCategoryId == 0) {
                final matchingCategory = categories.firstWhere(
                  (cat) => cat.name.toLowerCase().trim() == categoryIdStr.toLowerCase().trim(),
                  orElse: () => CategoryModel(id: 0, name: ''),
                );
                if (matchingCategory.id != 0) {
                  resolvedCategoryId = matchingCategory.id;
                  print('✅ Найдена категория по имени: "$categoryIdStr" → ID: ${matchingCategory.id}');
                } else {
                  print('⚠️ Категория не найдена по имени: "$categoryIdStr"');
                }
              }
            }
            
            // Update map with resolved categoryId
            if (resolvedCategoryId != null) {
              map['categoryid'] = resolvedCategoryId;
            }
            
            try {
              final product = ProductModel.fromMap(map);
              products.add(product);
              
              // Debug all products, especially Pepsi
              final productName = product.name.toLowerCase();
              if (productName.contains('pepsi') || i <= 3 || i == allRows.length - 1) {
                print('🔍 Продукт #$i: "${product.name}" (ID: ${product.id}), categoryId: ${product.categoryId}, barcode: ${product.barcode}');
              }
            } catch (e) {
              print('❌ Ошибка парсинга продукта в строке $i: $e');
              print('   Данные: id=${map['id']}, name=${map['name']}, categoryid=${map['categoryid']}');
            }
          } else {
            // Log rows without ID for debugging
            final nameValue = map['name']?.toString() ?? '';
            if (nameValue.isNotEmpty && nameValue.toLowerCase().contains('pepsi')) {
              print('⚠️ Найдена строка с "Pepsi", но без ID: $map');
            }
          }
        }

        // Sort by position
        products.sort((a, b) => a.position.compareTo(b.position));

        // Debug: Check if Pepsi is in the list
        final pepsiProducts = products.where((p) => p.name.toLowerCase().contains('pepsi')).toList();
        if (pepsiProducts.isNotEmpty) {
          print('✅ Найдено ${pepsiProducts.length} продукт(ов) с "Pepsi":');
          for (var p in pepsiProducts) {
            print('   - "${p.name}" (ID: ${p.id}, categoryId: ${p.categoryId}, barcode: ${p.barcode})');
          }
        } else {
          print('⚠️ Продукт "Pepsi" не найден в загруженных продуктах');
          print('   Всего загружено: ${products.length} продуктов');
          if (products.isNotEmpty) {
            print('   Примеры названий: ${products.take(5).map((p) => '"${p.name}"').join(", ")}');
          }
        }

        // Cache in Hive
        await HiveService.cacheProducts(products);

        print('✅ ${products.length} продукт аз Google Sheets гирифта шуд');
        return ProductLoadResult(products: products, fromCache: false);
      } catch (networkError) {
        print('⚠️ Ошибка сети при загрузке из Google Sheets: $networkError');
        // Try to load from cache if network fails (offline mode)
        final cachedProducts = await HiveService.getCachedProducts();
        if (cachedProducts.isNotEmpty) {
          print('📦 Используем кэш (офлайн режим): ${cachedProducts.length} продуктов');
          // Get categories from cache for resolving categoryId
          final categoryRepo = CategoryRepository();
          final categories = await categoryRepo.getAllCategories();
          
          final products = cachedProducts.map((map) {
            final categoryIdValue = map['categoryid'] ?? map['categoryId'];
            int? resolvedCategoryId;
            
            if (categoryIdValue != null) {
              final categoryIdStr = categoryIdValue.toString().trim();
              resolvedCategoryId = int.tryParse(categoryIdStr);
              
              if (resolvedCategoryId == null || resolvedCategoryId == 0) {
                final matchingCategory = categories.firstWhere(
                  (cat) => cat.name.toLowerCase().trim() == categoryIdStr.toLowerCase().trim(),
                  orElse: () => CategoryModel(id: 0, name: ''),
                );
                if (matchingCategory.id != 0) {
                  resolvedCategoryId = matchingCategory.id;
                  map['categoryid'] = resolvedCategoryId;
                }
              }
            }
            
            return ProductModel.fromMap(map);
          }).toList()
            ..sort((a, b) => a.position.compareTo(b.position));
          
          return ProductLoadResult(products: products, fromCache: true);
        }
        // If cache is also empty, return empty list
        return ProductLoadResult(products: [], fromCache: true);
      }
    } catch (e) {
      print('❌ Критическая ошибка getAllProducts(): $e');
      // Last resort: try to load from cache
      try {
        final cachedProducts = await HiveService.getCachedProducts();
        final products = cachedProducts.map((map) => ProductModel.fromMap(map)).toList();
        return ProductLoadResult(products: products, fromCache: true);
      } catch (cacheError) {
        print('❌ Ошибка загрузки из кэша: $cacheError');
        return ProductLoadResult(products: [], fromCache: true);
      }
    }
  }

  // Get all products (with cache) - for backward compatibility
  Future<List<ProductModel>> getAllProducts() async {
    final result = await getAllProductsWithCacheInfo();
    return result.products;
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    try {
      final allProducts = await getAllProducts();
      if (categoryId == 0) {
        // Return all products
        return allProducts;
      }
      return allProducts.where((p) => p.categoryId == categoryId).toList();
    } catch (e) {
      print('❌ Хатои getProductsByCategory(): $e');
      return [];
    }
  }

  // Add new product
  Future<bool> addProduct(ProductModel product) async {
    try {
      if (_worksheet == null) {
        await init();
      }

      await _worksheet!.values.appendRow([
        product.id,
        product.barcode,
        product.categoryId,
        product.name,
        product.imageBase64 ?? '',
        product.description ?? '',
        product.stock,
        product.stockSold,
        product.purchasePrice,
        product.salePrice,
        product.isFavorite,
        product.position,
        product.expireAt ?? '',
        product.piece ?? '',
        product.unit ?? '',
      ]);

      // Clear cache to force reload
      await HiveService.clearProductsCache();

      print('✅ Продукт "${product.name}" илова шуд');
      return true;
    } catch (e) {
      print('⚠️ Ошибка сети при добавлении продукта: $e');
      // Save to offline queue
      await HiveService.addPendingOperation('add_product', product.toMap());
      // Also save to cache immediately for offline display
      final cachedProducts = await HiveService.getCachedProducts();
      cachedProducts.add(product.toMap());
      await HiveService.cacheProducts(cachedProducts.map((map) => ProductModel.fromMap(map)).toList());
      print('📝 Продукт сохранен в офлайн очередь и кэш');
      return false; // Return false to indicate it wasn't saved to Google Sheets yet
    }
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty) return false;

      // Find row by id
      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty && row[0] == product.id.toString()) {
          // Delete old row and insert new one
          final rowIndex = i + 1;
          await _worksheet!.deleteRow(rowIndex);
          await _worksheet!.values.insertRow(rowIndex, [
            product.id,
            product.barcode,
            product.categoryId,
            product.name,
            product.imageBase64 ?? '',
            product.description ?? '',
            product.stock,
            product.stockSold,
            product.purchasePrice,
            product.salePrice,
            product.isFavorite,
            product.position,
            product.expireAt ?? '',
            product.piece ?? '',
            product.unit ?? '',
          ]);
          
          // Clear cache to force reload
          await HiveService.clearProductsCache();
          
          print('✅ Продукт "${product.name}" навсозӣ шуд');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Хатои updateProduct(): $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty) return false;

      // Find and delete row by id
      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty && row[0] == productId.toString()) {
          await _worksheet!.deleteRow(i + 1);
          
          // Clear cache to force reload
          await HiveService.clearProductsCache();
          
          print('✅ Продукт бо ID $productId нест шуд');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Хатои deleteProduct(): $e');
      return false;
    }
  }
}

