// Druga runda audytu reguł — ą/ę i ś/ć/ń/ź.
//
// Główne klasy zmian:
// 1) sc_wyjatek → sc_miekka — wszystkie 7 "wyjątków" są w rzeczywistości
//    przypadkami "ś/ź przed spółgłoską" (sc_miekka). Wyjątek to fuzzy
//    klasyfikacja; po przeniesieniu sc_wyjatek zostaje pusta enumeracja
//    do późniejszego rzeczywiście trudnego przypadku.
// 2) sc_miekka — poprawienie hintów dla słów gdzie po ś/ź stoi w piśmie
//    n/c, ale fonetycznie ń/ć (digraf ni/ci przed samogłoską).
// 3) ao_nosowka → ao_wymiana_ea — mężczyzna i rączka mają widoczną
//    wymianę ę↔ą przez „mąż" / „ręka" (klasyczne pokrewne wyrazy).
//
// Użycie:
//   dart run tools/fix_rules_v2.dart            # dry-run
//   dart run tools/fix_rules_v2.dart --apply    # wykonuje

import 'dart:convert';
import 'dart:io';

const _dir = 'assets/content/orthography';

class Fix {
  const Fix({required this.id, this.rule, this.hint});
  final String id;
  final String? rule;
  final String? hint;
}

const _fixes = <Fix>[
  // sc_wyjatek → sc_miekka (klasyfikacja prostsza, hinty czytelniejsze)
  Fix(id: 'prosba', rule: 'sc_miekka',
      hint: 'prośba — ś przed b'),
  Fix(id: 'kosc', rule: 'sc_miekka',
      hint: 'kość — kończy się na -ść'),
  Fix(id: 'gosc', rule: 'sc_miekka',
      hint: 'gość — kończy się na -ść'),
  Fix(id: 'masc', rule: 'sc_miekka',
      hint: 'maść — kończy się na -ść'),
  Fix(id: 'lisc', rule: 'sc_miekka',
      hint: 'liść — kończy się na -ść'),
  Fix(id: 'milosc', rule: 'sc_miekka',
      hint: 'miłość — kończy się na -ść'),
  Fix(id: 'pierscien', rule: 'sc_miekka',
      hint: 'pierścień — ś przed c (gdzie „ci" = miękkie ć)'),

  // sc_miekka — naprawa myllących hintów "X przed ń" (jest n+i = miękkie ń)
  Fix(id: 'laznia',
      hint: 'łaźnia — ź przed n (gdzie „ni" = miękkie ń)'),
  Fix(id: 'blizniak',
      hint: 'bliźniak — ź przed n (gdzie „ni" = miękkie ń)'),
  Fix(id: 'wisnia',
      hint: 'wiśnia — ś przed n (gdzie „ni" = miękkie ń)'),

  // ao_nosowka → ao_wymiana_ea (widoczna wymiana ę↔ą)
  Fix(id: 'mezczyzna', rule: 'ao_wymiana_ea',
      hint: 'mężczyzna → mąż (ę → ą)'),
  Fix(id: 'raczka', rule: 'ao_wymiana_ea',
      hint: 'rączka → ręka (ą → ę)'),
];

Future<void> main(List<String> argv) async {
  final apply = argv.contains('--apply');
  if (!apply) {
    stdout.writeln('DRY RUN — daj --apply żeby wykonać.\n');
  }

  final dir = Directory(_dir);
  final fixesById = {for (final f in _fixes) f.id: f};
  final remaining = Set.of(fixesById.keys);
  var totalChanges = 0;

  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final fileName = f.uri.pathSegments.last;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final words = (json['words'] as List).cast<Map<String, dynamic>>();

    var changesInFile = 0;
    for (final w in words) {
      final id = w['id'] as String;
      final fix = fixesById[id];
      if (fix == null) continue;
      remaining.remove(id);

      final oldRule = w['rule'] as String;
      final oldHint = w['example_hint'] as String;
      final newRule = fix.rule ?? oldRule;
      final newHint = fix.hint ?? oldHint;
      if (oldRule == newRule && oldHint == newHint) continue;

      stdout.writeln('  $fileName / $id');
      if (oldRule != newRule) {
        stdout.writeln('    rule: $oldRule → $newRule');
      }
      if (oldHint != newHint) {
        stdout.writeln('    hint: "$oldHint"');
        stdout.writeln('       → "$newHint"');
      }

      if (apply) {
        w['rule'] = newRule;
        w['example_hint'] = newHint;
      }
      changesInFile++;
      totalChanges++;
    }

    if (changesInFile > 0 && apply) {
      final encoder = JsonEncoder.withIndent('  ');
      f.writeAsStringSync(encoder.convert(json) + '\n');
    }
  }

  stdout.writeln('\n${apply ? "Zastosowano" : "Do zastosowania"}: '
      '$totalChanges zmian');

  if (remaining.isNotEmpty) {
    stderr.writeln('\n⚠ Nie znaleziono słów: ${remaining.join(", ")}');
    exit(1);
  }
}
