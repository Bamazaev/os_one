import 'package:gsheets/gsheets.dart';
import '../config/gsheets_config.dart';

/// Singleton service барои Google Sheets
/// Танҳо як маротиба инициализатсия мешавад
class GsheetsService {
  static GSheets? _gsheets;
  static Spreadsheet? _spreadsheet;
  static bool _initialized = false;

  /// Инициализатсия - танҳо як маротиба
  static Future<void> init() async {
    if (_initialized) {
      print('✅ GSheets аллакай инициализатсия шудааст');
      return;
    }

    try {
      print('🔄 Инициализатсияи Google Sheets...');
      _gsheets = GSheets(GsheetsConfig.credentials);
      _spreadsheet = await _gsheets!.spreadsheet(GsheetsConfig.spreadsheetId);
      _initialized = true;
      print('✅ Google Sheets инициализатсия шуд');
    } catch (e) {
      print('❌ Хатои GsheetsService.init(): $e');
      rethrow;
    }
  }

  /// Гирифтани worksheet аз ном (бо эҷод агар вуҷуд надошта бошад)
  static Future<Worksheet?> getOrCreateWorksheet(
    String title,
    List<String> headers,
  ) async {
    try {
      if (!_initialized || _spreadsheet == null) {
        await init();
      }

      // Ҷустуҷӯи worksheet мавҷуда
      var worksheet = _spreadsheet!.worksheetByTitle(title);

      // Эҷод кардан агар вуҷуд надорад
      if (worksheet == null) {
        print('🆕 Эҷоди worksheet: $title');
        worksheet = await _spreadsheet!.addWorksheet(title);
        await worksheet.values.insertRow(1, headers);
        print('✅ Worksheet "$title" эҷод шуд');
      } else {
        print('✅ Worksheet "$title" ёфт шуд');
      }

      return worksheet;
    } catch (e) {
      print('❌ Хатои getOrCreateWorksheet($title): $e');
      return null;
    }
  }

  /// Гирифтани GSheets instance
  static GSheets? get gsheets => _gsheets;

  /// Гирифтани Spreadsheet instance
  static Spreadsheet? get spreadsheet => _spreadsheet;

  /// Санҷиши инициализатсия
  static bool get isInitialized => _initialized;
}

