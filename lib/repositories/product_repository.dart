import 'package:gsheets/gsheets.dart';
import '../models/product_model.dart';
import '../services/hive_service.dart';
import '../services/gsheets_service.dart';

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

  // Get all products (with cache)
  Future<List<ProductModel>> getAllProducts() async {
    try {
      // Try to load from cache first
      final cachedProducts = await HiveService.getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        print('✅ ${cachedProducts.length} продукт аз cache гирифта шуд');
        return cachedProducts.map((map) => ProductModel.fromMap(map)).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
      }

      // Load from Google Sheets if cache is empty
      if (_worksheet == null) {
        await init();
      }

      final allRows = await _worksheet!.values.allRows();
      if (allRows.isEmpty || allRows.length < 2) {
        return [];
      }

      final headers = allRows.first;
      final products = <ProductModel>[];

      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        final map = <String, dynamic>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        if (map['id'] != null && map['id'].toString().isNotEmpty) {
          products.add(ProductModel.fromMap(map));
        }
      }

      // Sort by position
      products.sort((a, b) => a.position.compareTo(b.position));

      // Cache in Hive
      await HiveService.cacheProducts(products);

      print('✅ ${products.length} продукт аз Google Sheets гирифта шуд');
      return products;
    } catch (e) {
      print('❌ Хатои getAllProducts(): $e');
      // Try to load from cache if Google Sheets fails
      final cachedProducts = await HiveService.getCachedProducts();
      return cachedProducts.map((map) => ProductModel.fromMap(map)).toList();
    }
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
      print('❌ Хатои addProduct(): $e');
      return false;
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

