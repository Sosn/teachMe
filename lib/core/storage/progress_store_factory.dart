// Conditional export: na web ładowane jest `_web.dart` (InMemory),
// na pozostałych platformach `_io.dart` (JSON plik).
//
// Dart używa `dart.library.html`, żeby wykryć web (HTML DOM API).
export 'progress_store_factory_io.dart'
    if (dart.library.html) 'progress_store_factory_web.dart';
