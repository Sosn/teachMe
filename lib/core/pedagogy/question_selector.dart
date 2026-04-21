import 'dart:math';

import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';

/// Dobór słów do sesji. Priorytet:
/// 1. Słowa "due" (Leitner zegar mówi: pokaż dziś) i nowe (jeszcze
///    niewidziane) — mieszane razem, losowo dobierane.
/// 2. Jeśli powyższe nie wypełnią sesji — dokładamy "mastered" jako
///    lekką powtórkę.
///
/// Zasady wynikają z planu pedagogicznego: codzienne krótkie sesje 5–10
/// słów, mix starego/nowego, żeby dziecko nie czuło się ani zbytnio
/// wyzwaniem, ani znudzeniem (strefa najbliższego rozwoju).
class QuestionSelector {
  QuestionSelector._();

  static List<Word> pick({
    required List<Word> allWords,
    required Map<String, WordProgress> progressByWordId,
    required DateTime now,
    required int count,
    Random? random,
  }) {
    assert(count > 0, 'count musi być > 0');
    final rng = random ?? Random();

    final due = <Word>[];
    final fresh = <Word>[];
    final mastered = <Word>[];

    for (final w in allWords) {
      final progress = progressByWordId[w.id];
      if (progress == null || progress.isNew) {
        fresh.add(w);
      } else if (progress.mastered) {
        mastered.add(w);
      } else if (progress.isDue(now)) {
        due.add(w);
      }
      // nie-due, niezmasterowane — pomijamy (dopiero po upływie interwału).
    }

    final primary = [...due, ...fresh]..shuffle(rng);
    if (primary.length >= count) {
      return primary.take(count).toList();
    }

    final filler = [...mastered]..shuffle(rng);
    return [
      ...primary,
      ...filler.take(count - primary.length),
    ];
  }
}
