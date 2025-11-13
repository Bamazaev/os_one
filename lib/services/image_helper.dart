import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Pick and compress image for Google Sheets (max 50,000 characters)
  static Future<Map<String, dynamic>?> pickAndCompressImage() async {
    try {
      Uint8List? imageBytes;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: use file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: false,
        );

        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          imageBytes = await file.readAsBytes();
        }
      } else {
        // Mobile: use image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 70,
        );

        if (pickedFile != null) {
          imageBytes = await pickedFile.readAsBytes();
        }
      }

      if (imageBytes == null) return null;

      // Resize and compress image HEAVILY for Google Sheets
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('❌ Тасвирро decode карда натавонист');
        return null;
      }

      print('📐 Андозаи аслӣ: ${image.width}x${image.height}');

      // Resize to max 400px on longest side (SMALLER for Google Sheets limit)
      img.Image resized;
      if (image.width > image.height) {
        // Landscape or square
        resized = img.copyResize(image, width: 400);
      } else {
        // Portrait
        resized = img.copyResize(image, height: 400);
      }
      
      print('📐 Андозаи нав: ${resized.width}x${resized.height}');
      
      // Compress to JPEG with lower quality (70%) for Google Sheets
      final compressed = img.encodeJpg(resized, quality: 70);
      
      // Convert to base64
      final base64String = base64Encode(compressed);

      print('📊 Андозаи Base64: ${(base64String.length / 1024).toStringAsFixed(2)} KB');
      print('📊 Символҳо: ${base64String.length} (макс: 50000)');

      // Check if still too large
      if (base64String.length > 48000) {
        print('⚠️ Тасвир то ҳол калон аст, майдатар мекунем...');
        
        // Further resize to 300px if still too large
        img.Image smallerResized;
        if (resized.width > resized.height) {
          smallerResized = img.copyResize(resized, width: 300);
        } else {
          smallerResized = img.copyResize(resized, height: 300);
        }
        
        final smallerBytes = img.encodeJpg(smallerResized, quality: 65);
        final smallerBase64 = base64Encode(smallerBytes);
        
        print('📊 Андозаи нави Base64: ${(smallerBase64.length / 1024).toStringAsFixed(2)} KB');
        print('📊 Символҳо: ${smallerBase64.length}');
        
        return {
          'base64': smallerBase64,
          'bytes': Uint8List.fromList(smallerBytes),
        };
      }

      print('✅ Тасвир тайёр: ${compressed.length} bytes, base64: ${base64String.length} chars');

      return {
        'bytes': Uint8List.fromList(compressed),
        'base64': base64String,
      };
    } catch (e) {
      print('❌ Хатогӣ дар интихоби тасвир: $e');
      return null;
    }
  }
}

