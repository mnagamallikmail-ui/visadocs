import 'dart:typed_data';
import 'download_service_stub.dart'
    if (dart.library.html) 'download_service_web.dart'
    if (dart.library.io) 'download_service_io.dart';

abstract class DownloadService {
  static Future<String?> downloadAndOpenFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    return platformDownloadAndOpen(
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      filename: filename,
      mimeType: mimeType,
    );
  }
}

