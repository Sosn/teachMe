// Trzecia runda audytu — dodatkowe poprawki jakościowe i niespójności
// znalezione przy szczegółowym przeglądzie po v2.
//
// Klasy zmian:
// 1) Usunięcie terminu "rdzeń" (4 słowa: orzeł, jeżyna, jeżozwierz, kałuża).
// 2) Dziwne/niejasne hinty (3 słowa: burza, zorza, podróż).
// 3) Spójność hintów dla "ści-" cluster (4 słowa: ścieg, ściana, ścierka, ściółka).
// 4) ch_podstawowe — dodanie "do zapamiętania" do ~27 słów (oprócz tych
//    gdzie "ch na końcu" jest faktyczną regułą — tych nie ruszamy).
// 5) z_podstawowe — pełniejsze hinty (pozycja + "do zapamiętania").
// 6) huśtawka — etymologicznie rodzima (od "huśtać"), nie "wyraz obcy".
// 7) gąska — czystsza forma podstawowa (gęś zamiast gęsi).
// 8) ao_przed_pb — unifikacja formatu (3 słowa).
//
// Użycie:
//   dart run tools/fix_rules_v3.dart            # dry-run
//   dart run tools/fix_rules_v3.dart --apply    # wykonuje

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
  // 1) Usunięcie "rdzeń"
  Fix(id: 'orzel',
      hint: 'orzeł — rz w środku wyrazu, do zapamiętania'),
  Fix(id: 'jezyna',
      hint: 'jeżyna — ż w środku wyrazu, do zapamiętania'),
  Fix(id: 'jezozwierz',
      hint: 'jeżozwierz — ż w środku wyrazu, do zapamiętania'),
  Fix(id: 'kaluza',
      hint: 'kałuża — ż w środku wyrazu, do zapamiętania'),

  // 2) Dziwne/niepełne hinty
  Fix(id: 'burza',
      hint: 'burza — rz w środku wyrazu, do zapamiętania'),
  Fix(id: 'zorza',
      hint: 'zorza — rz w środku wyrazu, do zapamiętania'),
  Fix(id: 'podroz',
      hint: 'podróż — ż na końcu, do zapamiętania'),

  // 3) Spójność z pierścieniem (hinty „ś przed c (gdzie ci = miękkie ć)")
  Fix(id: 'scieg',
      hint: 'ścieg — ś przed c (gdzie „ci" = miękkie ć)'),
  Fix(id: 'sciana',
      hint: 'ściana — ś przed c (gdzie „ci" = miękkie ć)'),
  Fix(id: 'scierka',
      hint: 'ścierka — ś przed c (gdzie „ci" = miękkie ć)'),
  Fix(id: 'sciolka',
      hint: 'ściółka — ś przed c (gdzie „ci" = miękkie ć)'),

  // 4) ch_podstawowe — dodanie "do zapamiętania"
  // (pomijamy słowa z hintem "ch na końcu" — tam jest faktyczna reguła)
  Fix(id: 'chleb',
      hint: 'chleb — ch na początku, do zapamiętania'),
  Fix(id: 'kuchnia',
      hint: 'kuchnia — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'kocha',
      hint: 'kocha — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'chrabaszcz',
      hint: 'chrabąszcz — ch na początku, do zapamiętania'),
  Fix(id: 'chrzaszcz',
      hint: 'chrząszcz — ch na początku, do zapamiętania'),
  Fix(id: 'chlopiec',
      hint: 'chłopiec — ch na początku, do zapamiętania'),
  Fix(id: 'chochla',
      hint: 'chochla — ch na początku, do zapamiętania'),
  Fix(id: 'choroba',
      hint: 'choroba — ch na początku, do zapamiętania'),
  Fix(id: 'chryzantema',
      hint: 'chryzantema — ch na początku, do zapamiętania'),
  Fix(id: 'chmiel',
      hint: 'chmiel — ch na początku, do zapamiętania'),
  Fix(id: 'chlew',
      hint: 'chlew — ch na początku, do zapamiętania'),
  Fix(id: 'pchla',
      hint: 'pchła — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'chabry',
      hint: 'chabry — ch na początku, do zapamiętania'),
  Fix(id: 'rachunek',
      hint: 'rachunek — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'wachlarz',
      hint: 'wachlarz — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'chochlik',
      hint: 'chochlik — ch na początku, do zapamiętania'),
  Fix(id: 'chusteczka',
      hint: 'chusteczka — ch na początku, do zapamiętania'),
  Fix(id: 'chodnik',
      hint: 'chodnik — ch na początku, do zapamiętania'),
  Fix(id: 'mechanik',
      hint: 'mechanik — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'marchewka',
      hint: 'marchewka — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'chalka',
      hint: 'chałka — ch na początku, do zapamiętania'),
  Fix(id: 'chrust',
      hint: 'chrust — ch na początku, do zapamiętania'),
  Fix(id: 'muchomor',
      hint: 'muchomor — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'macocha',
      hint: 'macocha — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'kuchenka',
      hint: 'kuchenka — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'pochodnia',
      hint: 'pochodnia — ch w środku wyrazu, do zapamiętania'),
  Fix(id: 'suchar',
      hint: 'suchar — ch w środku wyrazu, do zapamiętania'),

  // 5) z_podstawowe — pełniejsze hinty
  Fix(id: 'jez',
      hint: 'jeż — ż na końcu, do zapamiętania'),
  Fix(id: 'maz',
      hint: 'mąż — ż na końcu, do zapamiętania'),
  Fix(id: 'roza',
      hint: 'róża — ż w środku wyrazu, do zapamiętania'),
  Fix(id: 'lozko',
      hint: 'łóżko — ż w środku wyrazu, do zapamiętania'),
  Fix(id: 'wieza',
      hint: 'wieża — ż w środku wyrazu, do zapamiętania'),
  Fix(id: 'kazdy',
      hint: 'każdy — ż w środku wyrazu, do zapamiętania'),
  Fix(id: 'ryz',
      hint: 'ryż — ż na końcu, do zapamiętania'),
  Fix(id: 'zelazo',
      hint: 'żelazo — ż na początku, do zapamiętania'),
  Fix(id: 'zubr',
      hint: 'żubr — ż na początku, do zapamiętania'),
  Fix(id: 'zyrafa',
      hint: 'żyrafa — ż na początku, do zapamiętania'),
  Fix(id: 'zurek',
      hint: 'żurek — ż na początku, do zapamiętania'),
  Fix(id: 'zuraw',
      hint: 'żuraw — ż na początku, do zapamiętania'),
  Fix(id: 'zyto',
      hint: 'żyto — ż na początku, do zapamiętania'),
  Fix(id: 'zaluzja',
      hint: 'żaluzja — ż na początku, do zapamiętania'),
  Fix(id: 'zwir',
      hint: 'żwir — ż na początku, do zapamiętania'),
  Fix(id: 'zoladz',
      hint: 'żołądź — ż na początku, do zapamiętania'),
  Fix(id: 'zagiel',
      hint: 'żagiel — ż na początku, do zapamiętania'),
  Fix(id: 'zonkil',
      hint: 'żonkil — ż na początku, do zapamiętania'),

  // 6) huśtawka — etymologicznie rodzima
  Fix(id: 'hustawka',
      hint: 'huśtawka — h na początku, do zapamiętania'),

  // 7) gąska — czystsza forma podstawowa
  Fix(id: 'gaska',
      hint: 'gąska → gęś (ą → ę)'),

  // 8) ao_przed_pb — unifikacja formatu
  Fix(id: 'traba',
      hint: 'trąba — ą przed b'),
  Fix(id: 'zeby',
      hint: 'zęby — ę przed b'),
  Fix(id: 'golab',
      hint: 'gołąb — ą przed b'),
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
      '$totalChanges zmian (z ${_fixes.length} zaplanowanych)');

  if (remaining.isNotEmpty) {
    stderr.writeln('\n⚠ Nie znaleziono słów: ${remaining.join(", ")}');
    exit(1);
  }
}
