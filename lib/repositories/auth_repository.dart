import 'package:gsheets/gsheets.dart';
import '../config/gsheets_config.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';

class AuthRepository {
  static const String _userSheetName = 'Users';

  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;
  Worksheet? _userSheet;

  /// Инициализация Google Sheets
  Future<void> init() async {
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
    } catch (e) {
      throw Exception('Хатогӣ дар пайваст ба Google Sheets: $e');
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
    await init();

    // Санҷиши email-и такрорӣ
    final allRows = await _userSheet!.values.allRows();
    for (var i = 1; i < allRows.length; i++) {
      if (allRows[i].length > 3 && allRows[i][3] == email) {
        throw Exception('Ин email аллакай қайд шудааст!');
      }
      if (allRows[i].length > 4 && allRows[i][4] == phone) {
        throw Exception('Ин телефон аллакай қайд шудааст!');
      }
    }

    // ID-и нави уникалӣ
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now().toIso8601String();

    // Илова кардан ба Google Sheets
    // Структура: id, name, lastName, email, phone, role, password, dateRegister, photoUrl, headerUrl
    await _userSheet!.values.appendRow([
      userId,                     // 0 - id
      name,                       // 1 - name
      lastName,                   // 2 - lastName
      email,                      // 3 - email
      phone,                      // 4 - phone
      'user',                     // 5 - role
      password,                   // 6 - password
      createdAt,                  // 7 - dateRegister
      photoBase64 ?? '',          // 8 - photoUrl (base64)
      headerBase64 ?? '',         // 9 - headerUrl (base64)
    ]);

    final user = UserModel(
      id: userId,
      name: name,
      lastName: lastName,
      email: email,
      phone: phone,
      role: 'user',
      photoUrl: photoBase64,
      headerUrl: headerBase64,
    );

    // Захира кардан дар Hive
    await HiveService.saveUser(user);
    await HiveService.setCurrentUserId(userId);

    return user;
  }

  /// Ворид шудан (Login)
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    await init();

    final allRows = await _userSheet!.values.allRows();
    
    // Ҷустуҷӯи корбар
    for (var i = 1; i < allRows.length; i++) {
      final row = allRows[i];
      if (row.length >= 7) {
        // Структура: id, name, lastName, email, phone, role, password
        final userPhone = row[4];  // phone дар индекс 4
        final userRole = row.length > 5 ? row[5] : 'user'; // role дар индекс 5
        final userPassword = row.length > 6 ? row[6] : ''; // password дар индекс 6

        if (userPhone == phone && userPassword == password) {
          final user = UserModel(
            id: row[0],
            name: row[1],
            lastName: row[2],
            email: row[3],
            phone: row[4],
            role: userRole,
            photoUrl: row.length > 8 ? row[8] : null,
            headerUrl: row.length > 9 ? row[9] : null,
          );

          // Захира кардан дар Hive
          await HiveService.saveUser(user);
          await HiveService.setCurrentUserId(user.id);
          
          return user;
        }
      }
    }

    throw Exception('Телефон ё парол нодуруст аст!');
  }

  /// Гирифтани корбари ҷорӣ
  Future<UserModel?> getCurrentUser() async {
    // Аввал аз Hive мегирем
    final localUser = HiveService.getCurrentUser();
    
    // Агар дар Hive набуд, аз Google Sheets мегирем
    if (localUser == null) {
      final userId = HiveService.getCurrentUserId();
      if (userId == null) return null;

      await init();
      final allRows = await _userSheet!.values.allRows();

      for (var i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty && row[0] == userId) {
          final user = UserModel(
            id: row[0],
            name: row.length > 1 ? row[1] : '',
            lastName: row.length > 2 ? row[2] : '',
            email: row.length > 3 ? row[3] : '',
            phone: row.length > 4 ? row[4] : '',
            role: row.length > 5 ? row[5] : 'user',
            photoUrl: row.length > 8 ? row[8] : null,
            headerUrl: row.length > 9 ? row[9] : null,
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
    await HiveService.clearCurrentUser();
  }
}

