import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/stats/stats_store.dart';
import 'package:teach_me/core/stats/stats_store_factory_io.dart';

void main() {
  final now = DateTime.utc(2026, 4, 19, 12);

  group('InMemoryStatsStore', () {
    late InMemoryStatsStore store;

    setUp(() => store = InMemoryStatsStore());

    test('pusty snapshot na początku', () async {
      final s = await store.load();
      expect(s.lifetime, isEmpty);
      expect(s.sinceReset, isEmpty);
      expect(s.lastResetAt, isEmpty);
    });

    test('recordSession dodaje do lifetime i sinceReset', () async {
      final s = await store.recordSession(
        OrthographyTopic.ouU,
        totalQuestions: 5,
        correctCount: 4,
        at: now,
      );
      expect(s.lifetimeFor(OrthographyTopic.ouU).sessions, 1);
      expect(s.lifetimeFor(OrthographyTopic.ouU).correct, 4);
      expect(s.sinceResetFor(OrthographyTopic.ouU).sessions, 1);
      expect(s.sinceResetFor(OrthographyTopic.ouU).correct, 4);
    });

    test('resetCategory zeruje sinceReset, lifetime zostaje', () async {
      await store.recordSession(
        OrthographyTopic.ouU,
        totalQuestions: 5,
        correctCount: 4,
        at: now.subtract(const Duration(hours: 1)),
      );
      final s = await store.resetCategory(OrthographyTopic.ouU, at: now);
      expect(s.lifetimeFor(OrthographyTopic.ouU).sessions, 1);
      expect(s.sinceResetFor(OrthographyTopic.ouU).sessions, 0);
      expect(s.lastResetFor(OrthographyTopic.ouU), now);
    });

    test('reset jednej kategorii nie wpływa na inne', () async {
      await store.recordSession(
        OrthographyTopic.ouU,
        totalQuestions: 5,
        correctCount: 3,
        at: now,
      );
      await store.recordSession(
        OrthographyTopic.rzZ,
        totalQuestions: 4,
        correctCount: 2,
        at: now,
      );
      final s = await store.resetCategory(OrthographyTopic.ouU, at: now);
      expect(s.sinceResetFor(OrthographyTopic.ouU).sessions, 0);
      expect(s.sinceResetFor(OrthographyTopic.rzZ).sessions, 1);
    });
  });

  group('JsonFileStatsStore', () {
    late Directory tempDir;
    late File file;
    late JsonFileStatsStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('teachme_stats_test_');
      file = File(p.join(tempDir.path, 'stats.json'));
      store = JsonFileStatsStore(file);
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('load na nieistniejącym pliku zwraca pusty snapshot', () async {
      final s = await store.load();
      expect(s.lifetime, isEmpty);
      expect(s.sinceReset, isEmpty);
    });

    test('recordSession + load round-trip przez plik', () async {
      await store.recordSession(
        OrthographyTopic.rzZ,
        totalQuestions: 3,
        correctCount: 2,
        at: now,
      );
      final reloaded = await JsonFileStatsStore(file).load();
      expect(reloaded.lifetimeFor(OrthographyTopic.rzZ).sessions, 1);
      expect(reloaded.lifetimeFor(OrthographyTopic.rzZ).questions, 3);
      expect(reloaded.lifetimeFor(OrthographyTopic.rzZ).correct, 2);
      expect(reloaded.lifetimeFor(OrthographyTopic.rzZ).lastSessionAt, now);
    });

    test('resetCategory + load zachowuje reset i timestamp', () async {
      await store.recordSession(
        OrthographyTopic.chH,
        totalQuestions: 4,
        correctCount: 4,
        at: now.subtract(const Duration(days: 1)),
      );
      await store.resetCategory(OrthographyTopic.chH, at: now);
      final reloaded = await JsonFileStatsStore(file).load();
      expect(reloaded.lifetimeFor(OrthographyTopic.chH).sessions, 1);
      expect(reloaded.sinceResetFor(OrthographyTopic.chH).sessions, 0);
      expect(reloaded.lastResetFor(OrthographyTopic.chH), now);
    });
  });
}
