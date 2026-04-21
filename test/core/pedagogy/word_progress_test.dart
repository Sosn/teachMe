import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';

void main() {
  final anchor = DateTime.utc(2026, 4, 19, 12);

  group('WordProgress.answered', () {
    test('nowe słowo (box 0) + poprawnie → box 2', () {
      const p = WordProgress(wordId: 'w1');
      final after = p.answered(correct: true, at: anchor);
      expect(after.box, 2);
      expect(after.correctCount, 1);
      expect(after.incorrectCount, 0);
      expect(after.lastReviewedAt, anchor);
    });

    test('nowe słowo (box 0) + błąd → box 1', () {
      const p = WordProgress(wordId: 'w1');
      final after = p.answered(correct: false, at: anchor);
      expect(after.box, 1);
      expect(after.correctCount, 0);
      expect(after.incorrectCount, 1);
    });

    test('błąd cofa z box 4 do 1 i zwiększa incorrectCount', () {
      const p = WordProgress(wordId: 'w1', box: 4, correctCount: 3);
      final after = p.answered(correct: false, at: anchor);
      expect(after.box, 1);
      expect(after.correctCount, 3);
      expect(after.incorrectCount, 1);
    });
  });

  group('WordProgress.mastered', () {
    test('box 5 i 3+ correct = mastered', () {
      const p = WordProgress(wordId: 'w1', box: 5, correctCount: 3);
      expect(p.mastered, isTrue);
    });

    test('box 5 ale 2 correct = jeszcze nie mastered', () {
      const p = WordProgress(wordId: 'w1', box: 5, correctCount: 2);
      expect(p.mastered, isFalse);
    });

    test('box 4 nigdy nie mastered niezależnie od correctCount', () {
      const p = WordProgress(wordId: 'w1', box: 4, correctCount: 10);
      expect(p.mastered, isFalse);
    });
  });

  group('WordProgress.isNew', () {
    test('box 0 i brak lastReviewedAt = nowe', () {
      const p = WordProgress(wordId: 'w1');
      expect(p.isNew, isTrue);
    });

    test('po pierwszej odpowiedzi już nie nowe', () {
      const p = WordProgress(wordId: 'w1');
      final after = p.answered(correct: true, at: anchor);
      expect(after.isNew, isFalse);
    });
  });
}
