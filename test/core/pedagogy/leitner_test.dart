import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/core/pedagogy/leitner.dart';

void main() {
  group('LeitnerBox.nextBox', () {
    test('poprawna odpowiedź awansuje o jedno pudełko', () {
      expect(LeitnerBox.nextBox(currentBox: 1, correct: true), 2);
      expect(LeitnerBox.nextBox(currentBox: 3, correct: true), 4);
    });

    test('błąd zawsze cofa do pudełka 1', () {
      expect(LeitnerBox.nextBox(currentBox: 5, correct: false), 1);
      expect(LeitnerBox.nextBox(currentBox: 2, correct: false), 1);
    });

    test('z pudełka 5 awans nie przekracza maxBox', () {
      expect(LeitnerBox.nextBox(currentBox: 5, correct: true), 5);
    });
  });

  group('LeitnerBox.nextReviewAt', () {
    final anchor = DateTime.utc(2026, 4, 19, 12);

    test('box 1 → następnego dnia', () {
      expect(
        LeitnerBox.nextReviewAt(box: 1, from: anchor),
        anchor.add(const Duration(days: 1)),
      );
    });

    test('box 5 → za 14 dni', () {
      expect(
        LeitnerBox.nextReviewAt(box: 5, from: anchor),
        anchor.add(const Duration(days: 14)),
      );
    });

    test('box 0 (nowe) → ten sam moment (od razu due)', () {
      expect(LeitnerBox.nextReviewAt(box: 0, from: anchor), anchor);
    });
  });

  group('LeitnerBox.isDue', () {
    final anchor = DateTime.utc(2026, 4, 19, 12);

    test('nowe słowo (lastReviewedAt == null) jest zawsze due', () {
      expect(
        LeitnerBox.isDue(box: 0, lastReviewedAt: null, now: anchor),
        isTrue,
      );
    });

    test('box 1 staje się due po jednym dniu', () {
      final lastReview = anchor.subtract(const Duration(hours: 23));
      expect(
        LeitnerBox.isDue(box: 1, lastReviewedAt: lastReview, now: anchor),
        isFalse,
      );
      final afterFullDay = anchor.add(const Duration(hours: 1));
      expect(
        LeitnerBox.isDue(box: 1, lastReviewedAt: lastReview, now: afterFullDay),
        isTrue,
      );
    });

    test('box 5 nie jest due zaraz po powtórce', () {
      expect(
        LeitnerBox.isDue(box: 5, lastReviewedAt: anchor, now: anchor),
        isFalse,
      );
    });
  });
}
