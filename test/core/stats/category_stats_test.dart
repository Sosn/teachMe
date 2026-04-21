import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/core/stats/category_stats.dart';

void main() {
  final now = DateTime.utc(2026, 4, 19, 12);

  group('CategoryStats.addSession', () {
    test('pierwsza sesja ustawia liczniki na wartości z sesji', () {
      const stats = CategoryStats();
      final after = stats.addSession(
        totalQuestions: 5,
        correctCount: 4,
        at: now,
      );
      expect(after.sessions, 1);
      expect(after.questions, 5);
      expect(after.correct, 4);
      expect(after.incorrect, 1);
      expect(after.lastSessionAt, now);
      expect(after.accuracy, closeTo(0.8, 0.001));
    });

    test('kolejna sesja kumuluje liczniki', () {
      final first = const CategoryStats().addSession(
        totalQuestions: 5,
        correctCount: 4,
        at: now.subtract(const Duration(days: 1)),
      );
      final second = first.addSession(
        totalQuestions: 4,
        correctCount: 2,
        at: now,
      );
      expect(second.sessions, 2);
      expect(second.questions, 9);
      expect(second.correct, 6);
      expect(second.incorrect, 3);
      expect(second.lastSessionAt, now);
    });
  });

  group('CategoryStats.accuracy', () {
    test('0 pytań → 0', () {
      expect(const CategoryStats().accuracy, 0);
    });

    test('100% poprawnych', () {
      final s = const CategoryStats().addSession(
        totalQuestions: 3,
        correctCount: 3,
        at: DateTime.now(),
      );
      expect(s.accuracy, 1.0);
    });
  });

  group('CategoryStats json round-trip', () {
    test('zachowuje wszystkie pola', () {
      final original = CategoryStats(
        sessions: 3,
        questions: 15,
        correct: 12,
        lastSessionAt: now,
      );
      final roundtrip = CategoryStats.fromJson(original.toJson());
      expect(roundtrip, original);
    });

    test('fromJson obsługuje brakujące klucze jako zero', () {
      final s = CategoryStats.fromJson(const {});
      expect(s.sessions, 0);
      expect(s.questions, 0);
      expect(s.correct, 0);
      expect(s.lastSessionAt, isNull);
    });
  });
}
