import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';
import 'package:teach_me/core/storage/progress_store_factory.dart';

/// Persystencja progresu nauki słów. Offline-first, bez backendu.
///
/// Dwie implementacje: JSON-plik (IO — Android, iOS, desktop) i pamięć
/// (Flutter web — nie mamy tam filesystem). Wybór przez conditional import
/// w `progress_store_factory.dart`.
abstract interface class ProgressStore {
  Future<Map<String, WordProgress>> loadAll();
  Future<void> save(WordProgress progress);
  Future<void> saveAll(Iterable<WordProgress> progresses);

  /// Usuwa progres (box, daty, licznik) dla wskazanych słów. Używane przy
  /// "Zresetuj kategorię" — odkłada słowa z powrotem do "nowe", żeby
  /// QuestionSelector znów je losował bez czekania na interwał Leitnera.
  Future<void> removeMany(Iterable<String> wordIds);
}

/// Implementacja in-memory — używana na webie oraz w testach, gdzie
/// nie chcemy dotykać dysku.
class InMemoryProgressStore implements ProgressStore {
  final Map<String, WordProgress> _data = {};

  @override
  Future<Map<String, WordProgress>> loadAll() async =>
      Map<String, WordProgress>.from(_data);

  @override
  Future<void> save(WordProgress progress) async {
    _data[progress.wordId] = progress;
  }

  @override
  Future<void> saveAll(Iterable<WordProgress> progresses) async {
    _data.clear();
    for (final p in progresses) {
      _data[p.wordId] = p;
    }
  }

  @override
  Future<void> removeMany(Iterable<String> wordIds) async {
    wordIds.forEach(_data.remove);
  }
}

final progressStoreProvider = FutureProvider<ProgressStore>((ref) async {
  return createProgressStore();
});
