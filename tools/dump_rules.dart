// Wyciąga wszystkie słowa z bazy ortografii w formie tabeli do analizy.
// Format: id | text | mask | correct | rule | example_hint | difficulty
// Użycie: dart run tools/dump_rules.dart > /tmp/rules.tsv

import 'dart:convert';
import 'dart:io';

const _dir = 'assets/content/orthography';

void main() {
  final dir = Directory(_dir);
  print('id\ttext\tmask\tcorrect\trule\texample_hint\tdifficulty\tfile');
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final words = (json['words'] as List).cast<Map<String, dynamic>>();
    final fileName = f.uri.pathSegments.last;
    for (final w in words) {
      print([
        w['id'], w['text'], w['mask'], w['correct'],
        w['rule'], w['example_hint'], w['difficulty'], fileName,
      ].join('\t'));
    }
  }
}
