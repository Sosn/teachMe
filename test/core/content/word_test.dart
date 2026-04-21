import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/core/content/ortho_rule.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word.dart';

void main() {
  group('Word.fromJson', () {
    test('parsuje kompletny rekord', () {
      final word = Word.fromJson(
        const {
          'id': 'woz',
          'text': 'wóz',
          'mask': 'w_z',
          'correct': 'ó',
          'distractor': 'u',
          'rule': 'ou_wymiana_o',
          'example_hint': 'wóz → wozu',
          'difficulty': 1,
        },
        topic: OrthographyTopic.ouU,
      );

      expect(word.id, 'woz');
      expect(word.text, 'wóz');
      expect(word.mask, 'w_z');
      expect(word.correct, 'ó');
      expect(word.distractor, 'u');
      expect(word.rule, OrthoRule.ouWymianaO);
      expect(word.topic, OrthographyTopic.ouU);
      expect(word.exampleHint, 'wóz → wozu');
      expect(word.difficulty, 1);
      expect(word.errorized, isNull);
    });

    test('parsuje opcjonalne pole errorized', () {
      final word = Word.fromJson(
        const {
          'id': 'maz',
          'text': 'mąż',
          'mask': 'mą_',
          'correct': 'ż',
          'distractor': 'rz',
          'rule': 'z_podstawowe',
          'example_hint': 'mąż',
          'difficulty': 2,
          'errorized': 'mąsz',
        },
        topic: OrthographyTopic.rzZ,
      );
      expect(word.errorized, 'mąsz');
    });

    test('rzuca StateError dla nieznanej reguły', () {
      expect(
        () => Word.fromJson(
          const {
            'id': 'x',
            'text': 'x',
            'mask': 'x_x',
            'correct': 'a',
            'distractor': 'b',
            'rule': 'nieznana_regula',
            'example_hint': '',
            'difficulty': 1,
          },
          topic: OrthographyTopic.ouU,
        ),
        throwsStateError,
      );
    });

    test('assertion odpala dla difficulty poza 1..5', () {
      expect(
        () => Word(
          id: 'x',
          text: 'x',
          mask: 'x_x',
          correct: 'a',
          distractor: 'b',
          rule: OrthoRule.uPodstawowe,
          topic: OrthographyTopic.ouU,
          exampleHint: '',
          difficulty: 6,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
