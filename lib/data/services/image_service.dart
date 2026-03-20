import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final _picker = ImagePicker();

  // Pilih dari galeri atau kamera
  static Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 50,  // kompres agar kecil
      maxWidth: 600,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Konversi file ke base64 string
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}