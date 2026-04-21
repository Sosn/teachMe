import 'package:meta/meta.dart';
import 'package:teach_me/core/pedagogy/leitner.dart';

/// Stan wiedzy dziecka na temat jednego słowa. Niemutowalny — każda odpowiedź
/// produkuje nową instancję. Pozwala prosto testować i persystować później.
@immutable
class WordProgress {
  const WordProgress({
    required this.wordId,
    this.box = 0,
    this.lastReviewedAt,
    this.correctCount = 0,
    this.incorrectCount = 0,
  });

  final String wordId;

  /// 0 = nigdy nie widziane, 1-5 = aktualne pudełko Leitnera.
  final int box;
  final DateTime? lastReviewedAt;
  final int correctCount;
  final int incorrectCount;

  /// Mastery: ostatnie pudełko + co najmniej 3 razy poprawnie łącznie.
  /// Samo dotarcie do box 5 jednym szczęśliwym strzałem nie liczy się
  /// jako opanowanie.
  bool get mastered => box >= LeitnerBox.maxBox && correctCount >= 3;

  bool get isNew => box == 0 && lastReviewedAt == null;

  /// Zwraca nowy WordProgress po odpowiedzi.
  WordProgress answered({
    required bool correct,
    required DateTime at,
  }) {
    final startingBox = box == 0 ? LeitnerBox.minBox : box;
    return WordProgress(
      wordId: wordId,
      box: LeitnerBox.nextBox(currentBox: startingBox, correct: correct),
      lastReviewedAt: at,
      correctCount: correct ? correctCount + 1 : correctCount,
      incorrectCount: correct ? incorrectCount : incorrectCount + 1,
    );
  }

  bool isDue(DateTime now) => LeitnerBox.isDue(
        box: box,
        lastReviewedAt: lastReviewedAt,
        now: now,
      );

  @override
  bool operator ==(Object other) =>
      other is WordProgress &&
      other.wordId == wordId &&
      other.box == box &&
      other.lastReviewedAt == lastReviewedAt &&
      other.correctCount == correctCount &&
      other.incorrectCount == incorrectCount;

  @override
  int get hashCode => Object.hash(
        wordId,
        box,
        lastReviewedAt,
        correctCount,
        incorrectCount,
      );

  @override
  String toString() => 'WordProgress(wordId: $wordId, box: $box, '
      'last: $lastReviewedAt, ok: $correctCount, err: $incorrectCount)';
}
