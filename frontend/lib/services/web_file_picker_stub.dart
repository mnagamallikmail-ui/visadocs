import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'download_service.dart';

class WebPickedFile {
  final String name;
  final Uint8List bytes;

  WebPickedFile({required this.name, required this.bytes});
}

class WebFilePicker {
  static Future<WebPickedFile?> pickFile({String? accept}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        Uint8List? fileBytes = platformFile.bytes;
        if (fileBytes == null && platformFile.path != null) {
          final file = File(platformFile.path!);
          if (await file.exists()) {
            fileBytes = await file.readAsBytes();
          }
        }
        if (fileBytes != null) {
          return WebPickedFile(name: platformFile.name, bytes: fileBytes);
        }
      }
    } catch (_) {}
    return null;
  }
}

void triggerBrowserDownload(List<int> bytes, String filename, String mimeType) {
  DownloadService.downloadAndOpenFile(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}
