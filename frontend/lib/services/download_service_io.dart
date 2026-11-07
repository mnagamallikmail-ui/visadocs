import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<String?> platformDownloadAndOpen({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  try {
    Directory? dir;
    if (Platform.isAndroid) {
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {}
      dir ??= await getExternalStorageDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('[DownloadService] File saved to: $filePath (${bytes.length} bytes)');

    // Attempt to open the downloaded deliverable directly via native viewer
    try {
      final openResult = await OpenFilex.open(filePath);
      debugPrint('[DownloadService] OpenFilex result: ${openResult.type} - ${openResult.message}');
    } catch (openErr) {
      debugPrint('[DownloadService] Auto-open failed (file is saved): $openErr');
    }

    return filePath;
  } catch (e) {
    debugPrint('[DownloadService] IO download error: $e');
    return null;
  }
}

