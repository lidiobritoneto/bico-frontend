import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class AvatarPicker {
  static Future<String?> pickImageAsBase64() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // importante pra pegar bytes no Windows
    );
    if (res == null || res.files.isEmpty) return null;

    final f = res.files.first;
    final Uint8List? bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return base64Encode(bytes);
  }
}