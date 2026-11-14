import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
    } catch (e) {
      debugPrint('[ShareService] Error sharing text: $e');
    }
  }

  static Future<void> shareFile({
    required String filePath,
    String? text,
    String? subject,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject,
      );
    } catch (e) {
      debugPrint('[ShareService] Error sharing file: $e');
    }
  }
}

