// Seleziona l'implementazione giusta: su web scarica davvero il file, altrove
// (test, desktop) non fa nulla.
export 'download_stub.dart' if (dart.library.js_interop) 'download_web.dart';
