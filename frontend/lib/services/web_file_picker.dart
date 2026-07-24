import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class WebPickedFile {
  final String name;
  final Uint8List bytes;

  WebPickedFile({required this.name, required this.bytes});
}

class WebFilePicker {
  static Future<WebPickedFile?> pickFile({String? accept}) async {
    final completer = Completer<WebPickedFile?>();
    
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    if (accept != null) {
      uploadInput.accept = accept;
    }
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          final resultBytes = reader.result;
          if (resultBytes != null) {
            Uint8List bytes;
            if (resultBytes is Uint8List) {
              bytes = resultBytes;
            } else if (resultBytes is ByteBuffer) {
              bytes = resultBytes.asUint8List();
            } else {
              try {
                bytes = Uint8List.fromList(resultBytes as List<int>);
              } catch (_) {
                completer.complete(null);
                return;
              }
            }
            completer.complete(WebPickedFile(
              name: file.name,
              bytes: bytes,
            ));
          } else {
            completer.complete(null);
          }
        });
        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }
    });
    
    uploadInput.onError.listen((e) {
      completer.complete(null);
    });
    
    uploadInput.click();
    
    return completer.future;
  }
}
