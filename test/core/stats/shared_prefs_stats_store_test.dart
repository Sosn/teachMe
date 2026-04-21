import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/stats/stats_store_factory_web.dart';

void main() {
  group('SharedPrefsStatsStore', () {
    late SharedPreferences prefs;
    late SharedPrefsStatsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = SharedPrefsStatsStore(prefs);
    });

    test('load pustego store zwraca pusty snapshot', () async {
      final snapshot = await store.load();
      expect(snapshot.lifetime, isEmpty);
      expect(snapshot.sinceReset, isEmpty);
      expect(snapshot.lastResetAt, isEmpty);
    });

    test('recordSession dodaje do lifetime i sinceReset', () async {
      final now = DateTime.utc(2026, 4, 20, 12);
      await store.recordSession(
        OrthographyTopic.ouU,
        totalQuestions: 5,
        correctCount: 4,
        at: now,
      );

      final snapshot = await store.load();
      expect(snapshot.lifetimeFor(OrthographyTopic.ouU).questions, 5);
      expect(snapshot.sinceResetFor(OrthographyTopic.ouU).questions, 5);
    });

    test('sesja przeżywa "restart" (nowa instancja store, te same prefs)',
        () async {
      final now = DateTime.utc(2026, 4, 20, 12);
      await store.recordSession(
        OrthographyTopic.rzZ,
        totalQuestions: 3,
        correctCount: 2,
        at: now,
      );

      final restarted = SharedPrefsStatsStore(prefs);
      final snapshot = await restarted.load();

      expect(snapshot.lifetimeFor(OrthographyTopic.rzZ).questions, 3);
      expect(snapshot.lifetimeFor(OrthographyTopic.rzZ).correct, 2);
    });

    test('resetCategory zeruje sinceReset, lifetime zostaje', () async {
      final now = DateTime.utc(2026, 4, 20, 12);
      await store.recordSession(
        OrthographyTopic.ouU,
        totalQuestions: 10,
        correctCount: 8,
        at: now,
      );
      await store.resetCategory(OrthographyTopic.ouU, at: now);

      final snapshot = await store.load();
      expect(snapshot.lifetimeFor(OrthographyTopic.ouU).questions, 10);
      expect(snapshot.sinceResetFor(OrthographyTopic.ouU).questions, 0);
      expect(snapshot.lastResetFor(OrthographyTopic.ouU), now);
    });
  });
}
