import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/category_model.dart';

class HiveService {
  static const String _userBoxName = 'users';
  static const String _currentUserKey = 'current_user_id';
  static const String _settingsBoxName = 'settings';
  static const String _categoryBoxName = 'categories';
  static const String _productBoxName = 'products';
  
  static Box<UserModel>? _userBox;
  static Box? _settingsBox;
  static Box? _categoryBox;
  static Box? _productBox;

  /// Инициализатсияи Hive
  static Future<void> init() async {
    try {
      // Барои Windows директорияи дуруст гирем
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final path = '${appDocDir.path}/os_one_hive';
        print('📁 Hive директория: $path');
        Hive.init(path);
      } else {
        await Hive.initFlutter();
      }
      
      // Қайд кардани адаптерҳо
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
        print('✅ UserModelAdapter қайд шуд');
      }
      // TODO: Uncomment after running: flutter pub run build_runner build
      // if (!Hive.isAdapterRegistered(1)) {
      //   Hive.registerAdapter(CategoryModelAdapter());
      //   print('✅ CategoryModelAdapter қайд шуд');
      // }
      
      // Кушодани boxes
      _userBox = await Hive.openBox<UserModel>(_userBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _categoryBox = await Hive.openBox(_categoryBoxName);
      _productBox = await Hive.openBox(_productBoxName);
      print('✅ Hive boxes кушода шуданд');
      print('📦 Users box дорад ${_userBox!.length} корбар');
      print('📦 Categories box дорад ${_categoryBox!.length} категория');
      print('📦 Products box дорад ${_productBox!.length} продукт');
      print('⚙️ Settings: ${_settingsBox!.keys.toList()}');
    } catch (e) {
      print('❌ Хатогӣ дар Hive.init: $e');
      rethrow;
    }
  }

  /// Захира кардани корбар
  static Future<void> saveUser(UserModel user) async {
    final box = _userBox ?? Hive.box<UserModel>(_userBoxName);
    await box.put(user.id, user);
    print('💾 Корбар захира шуд: ${user.name} (${user.id})');
  }

  /// Гирифтани корбар аз ID
  static UserModel? getUser(String userId) {
    final box = _userBox ?? Hive.box<UserModel>(_userBoxName);
    return box.get(userId);
  }

  /// Гирифтани ҳамаи корбарҳо
  static List<UserModel> getAllUsers() {
    final box = _userBox ?? Hive.box<UserModel>(_userBoxName);
    return box.values.toList();
  }

  /// Захира кардани ID-и корбари ҷорӣ
  static Future<void> setCurrentUserId(String userId) async {
    try {
      final box = _settingsBox ?? Hive.box(_settingsBoxName);
      await box.put(_currentUserKey, userId);
      await box.flush(); // Зарур кардани навиштан ба диск
      print('✅ setCurrentUserId захира шуд: $userId');
      
      // Санҷиш - оё дуруст захира шуд?
      final saved = box.get(_currentUserKey);
      print('🔍 Санҷиш: захирашуда = $saved');
    } catch (e) {
      print('❌ Хатогӣ дар setCurrentUserId: $e');
      rethrow;
    }
  }

  /// Гирифтани ID-и корбари ҷорӣ
  static String? getCurrentUserId() {
    try {
      final box = _settingsBox ?? Hive.box(_settingsBoxName);
      final userId = box.get(_currentUserKey) as String?;
      print('🔑 getCurrentUserId: $userId');
      return userId;
    } catch (e) {
      print('❌ Хатогӣ дар getCurrentUserId: $e');
      return null;
    }
  }

  /// Гирифтани корбари ҷорӣ
  static UserModel? getCurrentUser() {
    try {
      final userId = getCurrentUserId();
      print('🔍 HiveService.getCurrentUser - userId: $userId');
      if (userId == null) {
        print('❌ userId null аст');
        return null;
      }
      final user = getUser(userId);
      print('👤 User: ${user?.name ?? "null"}');
      return user;
    } catch (e) {
      print('❌ Хатогӣ дар getCurrentUser: $e');
      return null;
    }
  }

  /// Пок кардани корбари ҷорӣ (logout)
  static Future<void> clearCurrentUser() async {
    final box = _settingsBox ?? Hive.box(_settingsBoxName);
    await box.delete(_currentUserKey);
    print('🚪 Корбар logout шуд');
  }

  /// Пок кардани ҳамаи маълумот
  static Future<void> clearAll() async {
    final userBox = _userBox ?? Hive.box<UserModel>(_userBoxName);
    final settingsBox = _settingsBox ?? Hive.box(_settingsBoxName);
    await userBox.clear();
    await settingsBox.clear();
    print('🗑️ Ҳамаи маълумот пок шуд');
  }

  /// Нест кардани корбар
  static Future<void> deleteUser(String userId) async {
    final box = _userBox ?? Hive.box<UserModel>(_userBoxName);
    await box.delete(userId);
  }

  /// Навсозии корбар
  static Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  /// Санҷиши вуҷудияти корбар
  static bool hasUser(String userId) {
    final box = Hive.box<UserModel>(_userBoxName);
    return box.containsKey(userId);
  }

  /// Ҷустуҷӯи корбар аз email
  static UserModel? findUserByEmail(String email) {
    final users = getAllUsers();
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Ҷустуҷӯи корбар аз phone
  static UserModel? findUserByPhone(String phone) {
    final users = getAllUsers();
    try {
      return users.firstWhere((user) => user.phone == phone);
    } catch (e) {
      return null;
    }
  }

  /// Бастани ҳамаи boxes
  static Future<void> close() async {
    await Hive.close();
  }

  // ==================== CATEGORY METHODS ====================

  /// Cache категорияҳо дар Hive
  static Future<void> cacheCategories(List<CategoryModel> categories) async {
    final box = _categoryBox ?? Hive.box(_categoryBoxName);
    await box.clear();
    
    // Use sequential index instead of category ID to avoid Hive int range errors
    int index = 0;
    for (var category in categories) {
      await box.put(index, category.toMap());
      index++;
    }
    print('💾 ${categories.length} категория cache шуд');
  }

  /// Гирифтани категорияҳо аз cache
  static Future<List<CategoryModel>> getCachedCategories() async {
    final box = _categoryBox ?? Hive.box(_categoryBoxName);
    final categories = <CategoryModel>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          categories.add(CategoryModel.fromMap(Map<String, dynamic>.from(data)));
        } catch (e) {
          print('❌ Хатогӣ дар parse категория: $e');
        }
      }
    }
    
    categories.sort((a, b) => a.position.compareTo(b.position));
    print('📦 ${categories.length} категория аз cache гирифта шуд');
    return categories;
  }

  /// Гирифтани категория аз ID
  static CategoryModel? getCategoryById(int id) {
    final box = _categoryBox ?? Hive.box(_categoryBoxName);
    
    // Search through all categories since we use index as key
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          final category = CategoryModel.fromMap(Map<String, dynamic>.from(data));
          if (category.id == id) {
            return category;
          }
        } catch (e) {
          print('❌ Хатогӣ дар parse категория: $e');
        }
      }
    }
    return null;
  }

  /// Захира кардани 1 категория
  static Future<void> saveCategory(CategoryModel category) async {
    final box = _categoryBox ?? Hive.box(_categoryBoxName);
    
    // Find existing index or add new
    int? targetIndex;
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          final existingCategory = CategoryModel.fromMap(Map<String, dynamic>.from(data));
          if (existingCategory.id == category.id) {
            targetIndex = key as int;
            break;
          }
        } catch (e) {
          // Skip invalid data
        }
      }
    }
    
    // If not found, use next available index
    targetIndex ??= box.length;
    await box.put(targetIndex, category.toMap());
    print('💾 Категория захира шуд: ${category.name}');
  }

  /// Нест кардани категория
  static Future<void> deleteCategory(int id) async {
    final box = _categoryBox ?? Hive.box(_categoryBoxName);
    
    // Find and delete by category ID
    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          final category = CategoryModel.fromMap(Map<String, dynamic>.from(data));
          if (category.id == id) {
            await box.delete(key);
            print('🗑️ Категория бо ID $id нест шуд');
            return;
          }
        } catch (e) {
          // Skip invalid data
        }
      }
    }
    print('⚠️ Категория бо ID $id ёфт нашуд');
  }

  // ==================== PRODUCT METHODS ====================

  /// Cache продуктҳо дар Hive
  static Future<void> cacheProducts(List products) async {
    final box = _productBox ?? Hive.box(_productBoxName);
    await box.clear();
    
    // Use sequential index instead of product ID to avoid Hive int range errors
    int index = 0;
    for (var product in products) {
      final productMap = product is Map ? product : product.toMap();
      await box.put(index, productMap);
      index++;
    }
    print('💾 ${products.length} продукт cache шуд');
  }

  /// Гирифтани продуктҳо аз cache
  static Future<List<Map<String, dynamic>>> getCachedProducts() async {
    final box = _productBox ?? Hive.box(_productBoxName);
    final products = <Map<String, dynamic>>[];

    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        try {
          products.add(Map<String, dynamic>.from(data));
        } catch (e) {
          print('❌ Хатогӣ дар parse продукт: $e');
        }
      }
    }

    print('📦 ${products.length} продукт аз cache гирифта шуд');
    return products;
  }

  /// Пок кардани products cache
  static Future<void> clearProductsCache() async {
    final box = _productBox ?? Hive.box(_productBoxName);
    await box.clear();
    print('🗑️ Products cache пок шуд');
  }
}

