import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:teach_me/core/pedagogy/word_progress.dart';
import 'package:teach_me/core/storage/progress_store.dart';
import 'package:teach_me/core/storage/progress_store_factory_io.dart';

void main() {
  group('InMemoryProgressStore', () {
    late InMemoryProgressStore store;

    setUp(() => store = InMemoryProgressStore());

    test('loadAll pustego store zwraca pustą mapę', () async {
      expect(await store.loadAll(), isEmpty);
    });

    test('save + loadAll round-trip', () async {
      final now = DateTime.utc(2026, 4, 19, 12);
      await store.save(WordProgress(wordId: 'w1', box: 2, lastReviewedAt: now));
      final loaded = await store.loadAll();
      expect(loaded['w1']!.box, 2);
      expect(loaded['w1']!.lastReviewedAt, now);
    });

    test('saveAll zastępuje zawartość', () async {
      await store.save(const WordProgress(wordId: 'old'));
      await store.saveAll([const WordProgress(wordId: 'new', box: 3)]);
      final loaded = await store.loadAll();
      expect(loaded.keys, ['new']);
    });

    test('loadAll zwraca kopię (mutacje nie wpływają na store)', () async {
      await store.save(const WordProgress(wordId: 'w1'));
      final loaded = await store.loadAll();
      loaded.remove('w1');
      final again = await store.loadAll();
      expect(again, hasLength(1));
    });

    test('removeMany usuwa tylko wskazane słowa', () async {
      await store.save(const WordProgress(wordId: 'keep'));
      await store.save(const WordProgress(wordId: 'gone1', box: 3));
      await store.save(const WordProgress(wordId: 'gone2', box: 2));

      await store.removeMany(['gone1', 'gone2', 'not_there']);

      final loaded = await store.loadAll();
      expect(loaded.keys, ['keep']);
    });
  });

  group('JsonFileProgressStore', () {
    late Directory tempDir;
    late File file;
    late JsonFileProgressStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('teachme_store_test_');
      file = File(p.join(tempDir.path, 'progress.json'));
      store = JsonFileProgressStore(file);
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('loadAll na nieistniejącym pliku zwraca pustą mapę', () async {
      expect(await store.loadAll(), isEmpty);
    });

    test('save + loadAll round-trip zachowuje wszystkie pola', () async {
      final reviewedAt = DateTime.utc(2026, 4, 19, 12, 30, 45);
      final progress = WordProgress(
        wordId: 'woz',
        box: 3,
        lastReviewedAt: reviewedAt,
        correctCount: 5,
        incorrectCount: 1,
      );

      await store.save(progress);
      final loaded = await store.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded['woz'], progress);
    });

    test('save dwukrotne dla tego samego wordId nadpisuje', () async {
      final now = DateTime.utc(2026, 4, 19, 12);
      await store.save(WordProgress(wordId: 'woz', box: 1, lastReviewedAt: now));
      await store.save(WordProgress(wordId: 'woz', box: 3, lastReviewedAt: now));

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded['woz']!.box, 3);
    });

    test('saveAll zastępuje zawartość pliku', () async {
      await store.save(const WordProgress(wordId: 'old1'));
      await store.save(const WordProgress(wordId: 'old2'));

      await store.saveAll([
        const WordProgress(wordId: 'new1', box: 2),
      ]);

      final loaded = await store.loadAll();
      expect(loaded.keys, ['new1']);
    });

    test('loadAll poprawnie deserializuje wpis bez lastReviewedAt', () async {
      await store.save(const WordProgress(wordId: 'fresh'));
      final loaded = await store.loadAll();
      expect(loaded['fresh']!.lastReviewedAt, isNull);
      expect(loaded['fresh']!.isNew, isTrue);
    });

    test('tworzy katalog parent, jeśli nie istnieje', () async {
      final deep = File(p.join(tempDir.path, 'a', 'b', 'c', 'progress.json'));
      final deepStore = JsonFileProgressStore(deep);
      await deepStore.save(const WordProgress(wordId: 'x'));
      expect(deep.existsSync(), isTrue);
    });

    test('removeMany persystentnie usuwa wpisy z pliku', () async {
      await store.save(const WordProgress(wordId: 'keep', box: 2));
      await store.save(const WordProgress(wordId: 'drop', box: 4));

      await store.removeMany(['drop']);

      final fresh = JsonFileProgressStore(file);
      final loaded = await fresh.loadAll();
      expect(loaded.keys, ['keep']);
      expect(loaded['keep']!.box, 2);
    });
  });
}
