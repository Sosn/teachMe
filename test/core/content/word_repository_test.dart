import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/core/content/ortho_rule.dart';
import 'package:teach_me/core/content/word_repository.dart';

/// Loader z systemu plików — testy unit nie potrzebują rootBundle.
Future<String> _fileLoader(String assetPath) {
  return File(assetPath).readAsString();
}

const _topicPaths = [
  'assets/content/orthography/ou.json',
  'assets/content/orthography/rz_z.json',
  'assets/content/orthography/ch_h.json',
  'assets/content/orthography/ao_en.json',
  'assets/content/orthography/sc_nz.json',
];

void main() {
  group('WordRepository.loadAll', () {
    late WordRepository repo;

    setUp(() {
      repo = WordRepository.fromLoader(_fileLoader);
    });

    test('ładuje min. 80 słów z 5 plików tematycznych', () async {
      final words = await repo.loadAll();
      expect(words.length, greaterThanOrEqualTo(80));
    });

    test('każde słowo ma unikalny id (między plikami też)', () async {
      final words = await repo.loadAll();
      final ids = words.map((w) => w.id).toSet();
      expect(ids, hasLength(words.length));
    });

    test('maska każdego słowa zawiera dokładnie jedno _', () async {
      final words = await repo.loadAll();
      for (final w in words) {
        final underscores = w.mask.split('_').length - 1;
        expect(underscores, 1, reason: 'Słowo ${w.id} ma mask "${w.mask}"');
      }
    });

    test('correct wstawiony w lukę = text dla każdego słowa', () async {
      final words = await repo.loadAll();
      for (final w in words) {
        final reconstructed = w.mask.replaceAll('_', w.correct);
        expect(
          reconstructed,
          w.text,
          reason: 'Słowo ${w.id}: mask "${w.mask}" + correct "${w.correct}" '
              'dało "$reconstructed", oczekiwano "${w.text}"',
        );
      }
    });

    test('difficulty każdego słowa ∈ [1..5]', () async {
      final words = await repo.loadAll();
      for (final w in words) {
        expect(w.difficulty, inInclusiveRange(1, 5));
      }
    });

    test('używane są wszystkie 5 grup tematycznych', () async {
      final words = await repo.loadAll();
      final rules = words.map((w) => w.rule).toSet();
      // ó/u
      expect(rules, contains(OrthoRule.ouWymianaO));
      expect(rules, contains(OrthoRule.uPodstawowe));
      // rz/ż
      expect(rules, contains(OrthoRule.rzPoSpolgl));
      expect(rules, contains(OrthoRule.zPodstawowe));
      // ch/h
      expect(rules, contains(OrthoRule.chPodstawowe));
      expect(rules, contains(OrthoRule.hPodstawowe));
      // ą/ę
      expect(rules, contains(OrthoRule.aoNosowka));
      // ś/ć/ń/ź
      expect(rules, contains(OrthoRule.scMiekka));
    });

    test('wyjątki są reprezentowane w każdej grupie', () async {
      final words = await repo.loadAll();
      final rules = words.map((w) => w.rule).toSet();
      expect(rules, contains(OrthoRule.ouWyjatek));
      expect(rules, contains(OrthoRule.rzWyjatek));
    });

    test('posortowane po difficulty rosnąco', () async {
      final words = await repo.loadAll();
      for (var i = 1; i < words.length; i++) {
        expect(
          words[i].difficulty,
          greaterThanOrEqualTo(words[i - 1].difficulty),
        );
      }
    });

    test('każde exampleSentence zawiera word.text (lub Capitalized)',
        () async {
      final words = await repo.loadAll();
      final bad = <String>[];
      for (final w in words) {
        final sentence = w.exampleSentence;
        if (sentence == null) continue;
        final text = w.text;
        final cap = text.isEmpty
            ? text
            : text[0].toUpperCase() + text.substring(1);
        if (!sentence.contains(text) && !sentence.contains(cap)) {
          bad.add('${w.id}: brak "$text" w "$sentence"');
        }
      }
      expect(
        bad,
        isEmpty,
        reason:
            'FindError wymaga word.text w formie podstawowej w zdaniu.\n'
            'Złe zdania:\n  ${bad.join('\n  ')}',
      );
    });
  });

  group('zgodność rule id w każdym pliku JSON', () {
    test('każde rule id jest znane w OrthoRule', () async {
      final knownRuleIds = OrthoRule.values.map((r) => r.id).toSet();
      for (final path in _topicPaths) {
        final raw = await File(path).readAsString();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final words = (json['words'] as List).cast<Map<String, dynamic>>();
        final jsonRuleIds = words.map((w) => w['rule'] as String).toSet();
        final unknown = jsonRuleIds.difference(knownRuleIds);
        expect(
          unknown,
          isEmpty,
          reason: 'W pliku $path nieznane reguły: $unknown',
        );
      }
    });
  });
}
