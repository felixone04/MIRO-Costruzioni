import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Fa scaricare al browser un file con il nome indicato.
Future<void> saveBytes(Uint8List bytes, String name, String mime) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime.isEmpty ? 'application/octet-stream' : mime),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body?.append(a);
  a.click();
  a.remove();
  // Il browser ha già preso il file: l'indirizzo temporaneo si può liberare.
  Future<void>.delayed(
    const Duration(seconds: 2),
    () => web.URL.revokeObjectURL(url),
  );
}
