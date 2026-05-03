// Aplikuje poprawki reguł i hintów na podstawie audytu z 2026-04-30.
//
// Użycie:
//   dart run tools/fix_rules.dart            # dry-run
//   dart run tools/fix_rules.dart --apply    # wykonuje
//
// Każda zmiana może modyfikować: rule, example_hint (lub obie).
// Skrypt ostrzega jeśli słowo nie zostało znalezione — to znaczy, że
// audyt potrzebuje aktualizacji.

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
  // ===== ou.json =====
  // ou_wymiana_o → ou_wyjatek (brak realnej wymiany)
  Fix(id: 'klotnia', rule: 'ou_wyjatek',
      hint: 'kłótnia — pisownia do zapamiętania'),
  Fix(id: 'spoznic', rule: 'ou_wyjatek',
      hint: 'spóźnić — pisownia do zapamiętania'),
  Fix(id: 'plotno', rule: 'ou_wyjatek',
      hint: 'płótno — pisownia do zapamiętania'),

  // ou_wyjatek → ou_wymiana_o (wymiana faktycznie istnieje)
  Fix(id: 'pszczolka', rule: 'ou_wymiana_o',
      hint: 'pszczółka → pszczoła (ó → o)'),
  Fix(id: 'lodz', rule: 'ou_wymiana_o',
      hint: 'łódź → łodzie (ó → o)'),
  Fix(id: 'miod', rule: 'ou_wymiana_o',
      hint: 'miód → miody (ó → o)'),
  Fix(id: 'wrog', rule: 'ou_wymiana_o',
      hint: 'wróg → wrogowie (ó → o)'),
  Fix(id: 'bobr', rule: 'ou_wymiana_o',
      hint: 'bóbr → bobry (ó → o)'),
  Fix(id: 'glowka', rule: 'ou_wymiana_o',
      hint: 'główka → głowa (ó → o)'),

  // ou_wymiana_o — borderline → wyjątek (chorał to rzadkie słowo)
  Fix(id: 'chor', rule: 'ou_wyjatek',
      hint: 'chór — pisownia do zapamiętania'),

  // ou_wymiana_o — czystsze przykłady
  Fix(id: 'nozka', hint: 'nóżka → noga (ó → o)'),
  Fix(id: 'kolko', hint: 'kółko → koło (ó → o)'),

  // u_podstawowe — hinty zamiast "piszemy przez u"
  Fix(id: 'ul', hint: 'ul — u na początku wyrazu'),
  Fix(id: 'kula', hint: 'kula — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'chmura', hint: 'chmura — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'buty', hint: 'buty — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'kubek', hint: 'kubek — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'muszla', hint: 'muszla — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'lustro', hint: 'lustro — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'lupa', hint: 'lupa — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'truskawka', hint: 'truskawka — u w środku wyrazu, do zapamiętania'),
  Fix(id: 'kukurydza', hint: 'kukurydza — u w środku wyrazu, do zapamiętania'),

  // ===== rz_z.json =====
  // rz_po_spolgl → rz_podstawowe (rz po samogłosce, nie spółgłosce)
  Fix(id: 'jarzebina', rule: 'rz_podstawowe',
      hint: 'jarzębina — rz w środku wyrazu, do zapamiętania'),
  Fix(id: 'warzywa', rule: 'rz_podstawowe',
      hint: 'warzywa — rz w środku wyrazu, do zapamiętania'),
  Fix(id: 'tchorz', rule: 'rz_podstawowe',
      hint: 'tchórz — rz na końcu wyrazu, do zapamiętania'),

  // z_wymiana — czystszy przykład
  Fix(id: 'wazka',
      hint: 'ważka — od „ważyć", ż wymienia się na g (waga)'),

  // ===== ch_h.json =====
  // h_wymiana — błahy etymologicznie wymienia się na z, nie g
  Fix(id: 'blahy', hint: 'błahy → błazen (h → z)'),

  // ch_podstawowe — opisy słów zamiast reguły
  Fix(id: 'chata', hint: 'chata — ch na początku, do zapamiętania'),
  Fix(id: 'chusta', hint: 'chusta — ch na początku, do zapamiętania'),
  Fix(id: 'choinka', hint: 'choinka — ch na początku, do zapamiętania'),
  Fix(id: 'chomik', hint: 'chomik — ch na początku, do zapamiętania'),
  Fix(id: 'schody', hint: 'schody — ch po literze s'),

  // ===== ao_en.json =====
  // ao_wymiana_ea — błędny przykład (księgi ma ę)
  Fix(id: 'ksiega', hint: 'księga → ksiąg (ę → ą)'),

  // ao_nosowka → ao_wymiana_ea (jest oczywista wymiana)
  Fix(id: 'piaty', rule: 'ao_wymiana_ea',
      hint: 'piąty → pięć (ą → ę)'),
  Fix(id: 'waski', rule: 'ao_wymiana_ea',
      hint: 'wąski → węższy (ą → ę)'),
  Fix(id: 'galaz', rule: 'ao_wymiana_ea',
      hint: 'gałąź → gałęzie (ą → ę)'),
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
    stderr.writeln('Sprawdź id-y w bazie — może audyt jest nieaktualny.');
    exit(1);
  }
}
