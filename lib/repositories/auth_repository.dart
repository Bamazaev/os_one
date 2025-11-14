import 'package:gsheets/gsheets.dart';
import '../config/gsheets_config.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';
import '../utils/base64_helper.dart';

class AuthRepository {
  static const String _userSheetName = 'Users';

  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;
  Worksheet? _userSheet;

  /// Инициализация Google Sheets
  /// Возвращает true если успешно, false если нет интернета
  Future<bool> init() async {
    try {
      _gsheets = GSheets(kServiceAccountJson);
      _spreadsheet = await _gsheets!.spreadsheet(kSpreadsheetId);
      
      // Аввал саҳифаро бо номи "users" (бо ҳарфи хурд) меҷӯем
      _userSheet = _spreadsheet!.worksheetByTitle('users');
      
      // Агар "users" надошт, "Users" меҷӯем
      if (_userSheet == null) {
        _userSheet = _spreadsheet!.worksheetByTitle('Users');
      }
      
      // Агар ҳеҷ кадом вуҷуд надошт, саҳифаи нав эҷод мекунем
      if (_userSheet == null) {
        _userSheet = await _spreadsheet!.addWorksheet(_userSheetName);
        // Сарлавҳаро илова мекунем (мувофиқи структураи шумо)
        await _userSheet!.values.insertRow(1, [
          'id',
          'name',
          'lastName',
          'email',
          'phone',
          'role',
          'password',
          'dateRegister',
          'photoUrl',
          'headerUrl'
        ]);
      }
      return true;
    } catch (e) {
      // Улучшенная обработка ошибок
      final errorMessage = e.toString();
      if (errorMessage.contains('SocketFailed') || 
          errorMessage.contains('host lookup') ||
          errorMessage.contains('No address associated')) {
        print('📴 Интернет пайваст нест');
        return false; // Возвращаем false вместо исключения
      } else if (errorMessage.contains('oauth2') || errorMessage.contains('OAuth')) {
        print('📴 Ошибка OAuth - возможно нет интернета');
        return false;
      } else {
        // Другие ошибки пробрасываем
        throw Exception('Хатогӣ дар пайваст ба Google Sheets. Лутфан пайвасти интернетро санҷед.');
      }
    }
  }

  /// Қайд шудан (Register)
  Future<UserModel> register({
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? photoBase64,
    String? headerBase64,
  }) async {
    final hasInternet = await init();
    if (!hasInternet) {
      throw Exception('Барои қайд шудан интернет зарур аст. Лутфан пайвасти интернетро санҷед.');
    }

    // Санҷиши email-и такрорӣ
    final allRows = await _userSheet!.values.allRows();
    final normalizedPhone = _normalizePhone(phone);
    
    for (var i = 1; i < allRows.length; i++) {
      if (allRows[i].length > 3 && allRows[i][3] == email) {
        throw Exception('Ин email аллакай қайд шудааст!');
      }
      if (allRows[i].length > 4) {
        final existingPhone = allRows[i][4];
        final normalizedExistingPhone = _normalizePhone(existingPhone);
        if (normalizedExistingPhone == normalizedPhone) {
          throw Exception('Ин телефон аллакай қайд шудааст!');
        }
      }
    }

    // ID-и нави уникалӣ
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now().toIso8601String();

    // Илова кардан ба Google Sheets
    // Структура: id, name, lastName, email, phone, role, password, dateRegister, photoUrl, headerUrl
    // Google Sheets маҳдудияти 50000 character дар як cell дорад
    String? safePhotoBase64 = photoBase64;
    String? safeHeaderBase64 = headerBase64;
    
    // Санҷиш ва кам кардани андозаи фото агар зарур бошад
    if (safePhotoBase64 != null && safePhotoBase64.length > 45000) {
      print('⚠️ Photo base64 хеле калон аст (${safePhotoBase64.length} chars), пок карда мешавад');
      safePhotoBase64 = null; // Пок кардан агар хеле калон бошад
    }
    
    if (safeHeaderBase64 != null && safeHeaderBase64.length > 45000) {
      print('⚠️ Header base64 хеле калон аст (${safeHeaderBase64.length} chars), пок карда мешавад');
      safeHeaderBase64 = null; // Пок кардан агар хеле калон бошад
    }
    
    print('📝 Илова кардани корбар ба Google Sheets...');
    print('   ID: $userId');
    print('   Телефон: $phone');
    print('   Парол: *** (${password.length} chars)');
    
    try {
      await _userSheet!.values.appendRow([
        userId,                     // 0 - id
        name,                       // 1 - name
        lastName,                   // 2 - lastName
        email,                      // 3 - email
        phone,                      // 4 - phone
        'user',                     // 5 - role
        password,                   // 6 - password
        createdAt,                  // 7 - dateRegister
        safePhotoBase64 ?? '',      // 8 - photoUrl (base64)
        safeHeaderBase64 ?? '',     // 9 - headerUrl (base64)
      ]);
      
      print('✅ Корбар ба Google Sheets илова шуд');
      
      // Санҷиш - оё парол дуруст захира шуд?
      final allRows = await _userSheet!.values.allRows();
      if (allRows.length > 1) {
        final lastRow = allRows[allRows.length - 1];
        if (lastRow.length > 6) {
          final savedPassword = lastRow[6];
          print('🔍 Санҷиши парол дар Google Sheets:');
          print('   Пароли захирашуда: ${savedPassword.isNotEmpty ? "*** (${savedPassword.length} chars)" : "(холӣ) ❌"}');
          print('   Пароли воридшуда: *** (${password.length} chars)');
          print('   Муқоиса: ${savedPassword == password ? "✅ Дуруст" : "❌ Нодуруст"}');
          
          if (savedPassword != password) {
            print('⚠️ ВАРНИГАР! Парол дар Google Sheets нодуруст захира шуд!');
            print('   Парол дар Google Sheets: "$savedPassword"');
            print('   Пароли воридшуда: "$password"');
          }
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('50000') || errorMsg.contains('maximum')) {
        throw Exception('Фото ё фон хеле калон аст. Лутфан фотои хурдтарро интихоб кунед.');
      }
      rethrow;
    }

    final user = UserModel(
      id: userId,
      name: name,
      lastName: lastName,
      email: email,
      phone: phone,
      role: 'user',
      photoUrl: safePhotoBase64,  // Истифодаи safePhotoBase64
      headerUrl: safeHeaderBase64, // Истифодаи safeHeaderBase64
    );

    // Захира кардан дар Hive (с паролем для офлайн-режима)
    print('💾 Захираи корбар дар Hive...');
    await HiveService.saveUser(user);
    print('🔐 Захираи пароли корбар дар Hive...');
    await HiveService.saveUserPassword(userId, password);
    
    // Санҷиш - оё парол дуруст захира шуд?
    final savedPassword = HiveService.getUserPassword(userId);
    print('🔍 Санҷиши парол: Парол дар Hive ${savedPassword == password ? "дуруст ✅" : "нодуруст ❌"}');
    print('   Пароли захирашуда: ${savedPassword != null ? "***" : "NULL"}');
    print('   Пароли воридшуда: ***');
    
    print('⚙️ Гузоштани ID-и корбари ҷорӣ...');
    await HiveService.setCurrentUserId(userId);

    return user;
  }

  /// Ворид шудан (Login)
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    // 🔄 НАВКУНӢ: Аввал аз Hive санҷем (барои кори offline)
    print('🔍 Санҷиши корбар дар Hive...');
    final localUser = HiveService.findUserByPhone(phone);
    
    if (localUser != null) {
      // Корбар дар Hive ёфт шуд - санҷиши парол
      print('👤 Корбар дар Hive ёфт шуд: ${localUser.name} (ID: ${localUser.id})');
      final savedPassword = HiveService.getUserPassword(localUser.id);
      
      print('🔍 Санҷиши парол:');
      print('   Пароли захирашуда дар Hive: ${savedPassword != null ? "*** (${savedPassword.length} chars)" : "NULL ❌"}');
      print('   Пароли воридшуда: *** (${password.length} chars)');
      print('   Муқоиса: ${savedPassword == password ? "✅ Дуруст" : "❌ Нодуруст"}');
      
      if (savedPassword == password) {
        print('✅ Login аз Hive муваффақ шуд (offline mode): ${localUser.name}');
        await HiveService.setCurrentUserId(localUser.id);
        
        // 🔄 Дар пасзамина кӯшиш мекунем, маълумотро аз Google Sheets навсозӣ кунем
        // (агар интернет дошта бошем)
        _syncUserDataInBackground(phone, password);
        
        return localUser;
      } else {
        // Пароли нодуруст - кӯшиш мекунем аз Google Sheets
        print('⚠️ Парол дар Hive нодуруст, кӯшиш аз Google Sheets...');
        // Идома медиҳем ба санҷиш аз Google Sheets
      }
    }
    
    // Агар дар Hive нест, аз Google Sheets мегирем (бояд интернет дошта бошем)
    print('📡 Корбар дар Hive нест, пайваст ба Google Sheets...');
    final hasInternet = await init();
    
    if (!hasInternet) {
      throw Exception('Барои воридшавии аввал интернет зарур аст. Лутфан пайвасти интернетро санҷед.');
    }

    // Санҷиш аз Google Sheets
    try {
      print('📊 Гирифтани ҳамаи сатрҳо аз Google Sheets...');
      final allRows = await _userSheet!.values.allRows();
      print('📊 Пайдо шуд: ${allRows.length} сатр');
      
      // Normalize кардани телефон барои муқоиса
      final normalizedPhone = _normalizePhone(phone);
      print('🔍 Ҷустуҷӯи телефон: $phone (normalized: $normalizedPhone)');
      
      // Ҷустуҷӯи корбар
      for (var i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        print('  🔍 Сатри $i: ${row.length} устун');
        
        if (row.length >= 7) {
          // Структура: id, name, lastName, email, phone, role, password
          final userPhone = row[4];  // phone дар индекс 4
          final userRole = row.length > 5 ? row[5] : 'user'; // role дар индекс 5
          final userPassword = row.length > 6 ? row[6] : ''; // password дар индекс 6
          
          // Normalize кардани телефон аз Google Sheets барои муқоиса
          final normalizedUserPhone = _normalizePhone(userPhone);
          print('  📱 Телефон дар сатр: $userPhone (normalized: $normalizedUserPhone)');
          print('  🔐 Парол дар сатр: ${userPassword.isNotEmpty ? "*** (${userPassword.length} chars)" : "(холӣ)"}');
          print('  🔐 Пароли воридшуда: *** (${password.length} chars)');
          print('  🔍 Муқоиса: normalizedPhone=${normalizedUserPhone == normalizedPhone ? "✅" : "❌"}, password=${userPassword == password ? "✅" : "❌"}');
          
          // Тафсилоти бештар барои debug
          if (normalizedUserPhone == normalizedPhone && userPassword != password) {
            print('  ⚠️ Телефон дуруст аст, аммо парол нодуруст!');
            print('     Парол дар Google Sheets: "$userPassword"');
            print('     Пароли воридшуда: "$password"');
          }

          if (normalizedUserPhone == normalizedPhone && userPassword == password) {
            print('🎯 Корбар ёфт шуд! Захира дар Hive...');
            
            // Очищаем base64 от префикса data URI если он есть
            final rawPhotoUrl = row.length > 8 ? row[8] : null;
            final cleanPhotoUrl = rawPhotoUrl != null && rawPhotoUrl.toString().isNotEmpty 
                ? cleanBase64String(rawPhotoUrl.toString()) 
                : null;
            
            final rawHeaderUrl = row.length > 9 ? row[9] : null;
            final cleanHeaderUrl = rawHeaderUrl != null && rawHeaderUrl.toString().isNotEmpty 
                ? cleanBase64String(rawHeaderUrl.toString()) 
                : null;
            
            final user = UserModel(
              id: row[0],
              name: row[1],
              lastName: row[2],
              email: row[3],
              phone: row[4],
              role: userRole,
              photoUrl: cleanPhotoUrl,
              headerUrl: cleanHeaderUrl,
            );

            // Захира кардан дар Hive (с паролем для офлайн-режима)
            print('💾 Захираи корбар дар Hive...');
            await HiveService.saveUser(user);
            print('🔐 Захираи пароли корбар...');
            await HiveService.saveUserPassword(user.id, password);
            print('⚙️ Гузоштани ID-и корбари ҷорӣ...');
            await HiveService.setCurrentUserId(user.id);
            
            print('✅ Login аз Google Sheets муваффақ шуд ва дар Hive захира шуд');
            
            // Санҷиши ниҳоӣ - оё дар Hive захира шуд?
            final savedUser = HiveService.getUser(user.id);
            print('🔍 Санҷиши ниҳоӣ: Корбар дар Hive ${savedUser != null ? "ҲАСТ ✅" : "НЕСТ ❌"}');
            
            return user;
          }
        }
      }

      print('❌ Ҳеҷ корбар бо ин телефон ва парол ёфт нашуд');
      print('   Телефон: $phone (normalized: $normalizedPhone)');
      print('   Парол: ${password.isNotEmpty ? "***" : "(холӣ)"}');
      throw Exception('Телефон ё парол нодуруст аст!');
    } catch (e) {
      print('❌ Хатогӣ дар санҷиш аз Google Sheets: $e');
      // Если ошибка при работе с Google Sheets, пробрасываем
      rethrow;
    }
  }
  
  /// Навсозии маълумоти корбар дар пасзамина (агар интернет дошта бошем)
  Future<void> _syncUserDataInBackground(String phone, String password) async {
    try {
      final hasInternet = await init();
      if (hasInternet) {
        final allRows = await _userSheet!.values.allRows();
        final normalizedPhone = _normalizePhone(phone);
        
        for (var i = 1; i < allRows.length; i++) {
          final row = allRows[i];
          if (row.length >= 7) {
            final userPhone = row[4];
            final normalizedUserPhone = _normalizePhone(userPhone);
            final userPassword = row.length > 6 ? row[6] : '';

            if (normalizedUserPhone == normalizedPhone && userPassword == password) {
              final rawPhotoUrl = row.length > 8 ? row[8] : null;
              final cleanPhotoUrl = rawPhotoUrl != null && rawPhotoUrl.toString().isNotEmpty 
                  ? cleanBase64String(rawPhotoUrl.toString()) 
                  : null;
              
              final rawHeaderUrl = row.length > 9 ? row[9] : null;
              final cleanHeaderUrl = rawHeaderUrl != null && rawHeaderUrl.toString().isNotEmpty 
                  ? cleanBase64String(rawHeaderUrl.toString()) 
                  : null;
              
              final user = UserModel(
                id: row[0],
                name: row[1],
                lastName: row[2],
                email: row[3],
                phone: row[4],
                role: row.length > 5 ? row[5] : 'user',
                photoUrl: cleanPhotoUrl,
                headerUrl: cleanHeaderUrl,
              );

              // Навсозии маълумот дар Hive
              await HiveService.saveUser(user);
              print('🔄 Маълумоти корбар аз Google Sheets навсозӣ шуд');
              break;
            }
          }
        }
      }
    } catch (e) {
      // Хатогӣҳоро нодида мегирем, зеро ин пасзаминавӣ аст
      print('ℹ️ Background sync хатогӣ дошт (норматӣ): $e');
    }
  }

  /// Гирифтани корбари ҷорӣ
  Future<UserModel?> getCurrentUser() async {
    // Аввал аз Hive мегирем
    final localUser = HiveService.getCurrentUser();
    
    // Агар дар Hive набуд, пытаемся загрузить из Google Sheets (если есть интернет)
    if (localUser == null) {
      final userId = HiveService.getCurrentUserId();
      if (userId == null) return null;

      final hasInternet = await init();
      if (!hasInternet) {
        // Нет интернета и нет пользователя в Hive
        return null;
      }
      final allRows = await _userSheet!.values.allRows();

      for (var i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty && row[0] == userId) {
          // Очищаем base64 от префикса data URI если он есть
          final rawPhotoUrl = row.length > 8 ? row[8] : null;
          final cleanPhotoUrl = rawPhotoUrl != null && rawPhotoUrl.toString().isNotEmpty 
              ? cleanBase64String(rawPhotoUrl.toString()) 
              : null;
          
          final rawHeaderUrl = row.length > 9 ? row[9] : null;
          final cleanHeaderUrl = rawHeaderUrl != null && rawHeaderUrl.toString().isNotEmpty 
              ? cleanBase64String(rawHeaderUrl.toString()) 
              : null;
          
          final user = UserModel(
            id: row[0],
            name: row.length > 1 ? row[1] : '',
            lastName: row.length > 2 ? row[2] : '',
            email: row.length > 3 ? row[3] : '',
            phone: row.length > 4 ? row[4] : '',
            role: row.length > 5 ? row[5] : 'user',
            photoUrl: cleanPhotoUrl,
            headerUrl: cleanHeaderUrl,
          );
          
          // Захира дар Hive
          await HiveService.saveUser(user);
          return user;
        }
      }
      return null;
    }
    
    return localUser;
  }

  /// Баромадан (Logout)
  Future<void> logout() async {
    final currentUserId = HiveService.getCurrentUserId();
    if (currentUserId != null) {
      await HiveService.clearUserPassword(currentUserId);
    }
    await HiveService.clearCurrentUser();
  }
  
  /// Normalize кардани телефон (пок кардани +, боскаҳо, тире ва ғ.)
  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }
}

