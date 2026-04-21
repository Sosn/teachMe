import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/core/content/ortho_rule.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/core/pedagogy/leitner.dart';
import 'package:teach_me/core/pedagogy/question_selector.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';

Word _word(String id, {int difficulty = 1}) => Word(
      id: id,
      text: id,
      mask: '${id[0]}_${id.substring(1)}',
      correct: 'ó',
      distractor: 'u',
      rule: OrthoRule.uPodstawowe,
      topic: OrthographyTopic.ouU,
      exampleHint: '',
      difficulty: difficulty,
    );

void main() {
  final now = DateTime.utc(2026, 4, 19, 12);

  group('QuestionSelector.pick', () {
    test('zwraca dokładnie count słów, gdy jest ich dość', () {
      final words = List.generate(10, (i) => _word('w$i'));
      final picked = QuestionSelector.pick(
        allWords: words,
        progressByWordId: const {},
        now: now,
        count: 5,
        random: Random(1),
      );
      expect(picked, hasLength(5));
    });

    test('same nowe słowa + żadnego progresu = wszystkie są kandydatami', () {
      final words = List.generate(3, (i) => _word('w$i'));
      final picked = QuestionSelector.pick(
        allWords: words,
        progressByWordId: const {},
        now: now,
        count: 10,
        random: Random(1),
      );
      expect(picked, hasLength(3));
      expect(picked.map((w) => w.id).toSet(), {'w0', 'w1', 'w2'});
    });

    test('mastered słowa są fillerem, nie pojawiają się dopóki są due/new', () {
      final words = [_word('due1'), _word('new1'), _word('mas1')];
      final progress = {
        'due1': WordProgress(
          wordId: 'due1',
          box: 2,
          lastReviewedAt: now.subtract(const Duration(days: 5)),
        ),
        'mas1': WordProgress(
          wordId: 'mas1',
          box: LeitnerBox.maxBox,
          correctCount: 3,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
        ),
      };
      final picked = QuestionSelector.pick(
        allWords: words,
        progressByWordId: progress,
        now: now,
        count: 2,
        random: Random(1),
      );
      expect(picked.map((w) => w.id).toSet(), {'due1', 'new1'});
    });

    test(
        'gdy nie starcza due+new, dokłada mastered do pełnej liczby count',
        () {
      final words = [
        _word('due1'),
        _word('mas1'),
        _word('mas2'),
        _word('mas3'),
      ];
      final progress = {
        'due1': WordProgress(
          wordId: 'due1',
          box: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
        ),
        'mas1': WordProgress(
          wordId: 'mas1',
          box: LeitnerBox.maxBox,
          correctCount: 3,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
        ),
        'mas2': WordProgress(
          wordId: 'mas2',
          box: LeitnerBox.maxBox,
          correctCount: 3,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
        ),
        'mas3': WordProgress(
          wordId: 'mas3',
          box: LeitnerBox.maxBox,
          correctCount: 3,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
        ),
      };
      final picked = QuestionSelector.pick(
        allWords: words,
        progressByWordId: progress,
        now: now,
        count: 3,
        random: Random(1),
      );
      expect(picked, hasLength(3));
      expect(picked.any((w) => w.id == 'due1'), isTrue);
      // pozostałe 2 z mastered
    });

    test('pomija słowa nie-due i niezmasterowane (w trakcie interwału)', () {
      final words = [_word('due1'), _word('waiting1')];
      final progress = {
        'due1': WordProgress(
          wordId: 'due1',
          box: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
        ),
        // box 3 → interwał 4 dni; ostatnio 1 dzień temu → jeszcze nie due
        'waiting1': WordProgress(
          wordId: 'waiting1',
          box: 3,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
        ),
      };
      final picked = QuestionSelector.pick(
        allWords: words,
        progressByWordId: progress,
        now: now,
        count: 5,
        random: Random(1),
      );
      expect(picked.map((w) => w.id), ['due1']);
    });

    test('seed Random gwarantuje determinizm', () {
      final words = List.generate(10, (i) => _word('w$i'));
      final first = QuestionSelector.pick(
        allWords: words,
        progressByWordId: const {},
        now: now,
        count: 5,
        random: Random(42),
      );
      final second = QuestionSelector.pick(
        allWords: words,
        progressByWordId: const {},
        now: now,
        count: 5,
        random: Random(42),
      );
      expect(
        first.map((w) => w.id).toList(),
        second.map((w) => w.id).toList(),
      );
    });
  });
}
