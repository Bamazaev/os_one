import 'dart:convert';
import 'dart:typed_data';

/// Очищает base64 строку от префикса data URI
/// Преобразует "data:image/jpeg;base64,/9j/4AAQ..." в "/9j/4AAQ..."
String? cleanBase64String(String? base64String) {
  if (base64String == null || base64String.isEmpty) {
    return null;
  }

  String cleanBase64 = base64String.trim();
  
  // Удаляем префикс data URI если он есть
  if (cleanBase64.startsWith('data:')) {
    // Формат: data:image/jpeg;base64,/9j/4AAQ...
    final commaIndex = cleanBase64.indexOf(',');
    if (commaIndex != -1) {
      cleanBase64 = cleanBase64.substring(commaIndex + 1);
    } else {
      // Если нет запятой, но есть префикс data:, возвращаем null
      print('⚠️ Неверный формат data URI: нет запятой');
      return null;
    }
  }

  return cleanBase64.isEmpty ? null : cleanBase64;
}

/// Вспомогательная функция для безопасного декодирования base64
/// Обрабатывает как чистый base64, так и data URI формат (data:image/jpeg;base64,...)
Uint8List? safeBase64Decode(String? base64String) {
  if (base64String == null || base64String.isEmpty) {
    return null;
  }

  try {
    // Очищаем строку от префикса data URI
    final cleanBase64 = cleanBase64String(base64String);
    if (cleanBase64 == null) {
      return null;
    }

    // Декодируем base64
    return base64Decode(cleanBase64);
  } catch (e) {
    print('❌ Ошибка декодирования base64: $e');
    final preview = base64String.length > 50 
        ? '${base64String.substring(0, 50)}...' 
        : base64String;
    print('   Строка начинается с: $preview');
    return null;
  }
}

