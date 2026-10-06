import 'dart:async';
import 'dart:typed_data';

class WebPickedFile {
  final String name;
  final Uint8List bytes;

  WebPickedFile({required this.name, required this.bytes});
}

class WebFilePicker {
  static Future<WebPickedFile?> pickFile({String? accept}) async {
    return null;
  }
}

void triggerBrowserDownload(List<int> bytes, String filename, String mimeType) {
  // No-op for non-web platforms / VM tests
}
