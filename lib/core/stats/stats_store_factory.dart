// Conditional export: web używa InMemory, inne platformy JSON plik.
export 'stats_store_factory_io.dart'
    if (dart.library.html) 'stats_store_factory_web.dart';
