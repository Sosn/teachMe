import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';
import 'package:teach_me/core/storage/progress_store_factory_web.dart';

void main() {
  group('SharedPrefsProgressStore', () {
    late SharedPreferences prefs;
    late SharedPrefsProgressStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = SharedPrefsProgressStore(prefs);
    });

    test('loadAll pustego store zwraca pustą mapę', () async {
      expect(await store.loadAll(), isEmpty);
    });

    test('save + loadAll round-trip zachowuje wszystkie pola', () async {
      final reviewedAt = DateTime.utc(2026, 4, 20, 10, 15);
      final progress = WordProgress(
        wordId: 'woz',
        box: 3,
        lastReviewedAt: reviewedAt,
        correctCount: 4,
        incorrectCount: 1,
      );

      await store.save(progress);
      final loaded = await store.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded['woz'], progress);
    });

    test('save przeżywa "restart" (nowa instancja store na tych samych prefs)',
        () async {
      await store.save(const WordProgress(wordId: 'keep', box: 2));

      // Nowy store na tym samym prefs — symulacja odświeżenia strony.
      final restarted = SharedPrefsProgressStore(prefs);
      final loaded = await restarted.loadAll();

      expect(loaded.keys, ['keep']);
      expect(loaded['keep']!.box, 2);
    });

    test('removeMany usuwa tylko wskazane słowa', () async {
      await store.save(const WordProgress(wordId: 'keep'));
      await store.save(const WordProgress(wordId: 'drop1', box: 3));
      await store.save(const WordProgress(wordId: 'drop2', box: 4));

      await store.removeMany(['drop1', 'drop2']);

      final loaded = await store.loadAll();
      expect(loaded.keys, ['keep']);
    });

    test('saveAll zastępuje zawartość', () async {
      await store.save(const WordProgress(wordId: 'old'));
      await store.saveAll([
        const WordProgress(wordId: 'new1', box: 2),
        const WordProgress(wordId: 'new2', box: 3),
      ]);

      final loaded = await store.loadAll();
      expect(loaded.keys.toSet(), {'new1', 'new2'});
    });
  });
}
