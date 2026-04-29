// Skanuje wszystkie pliki ortografii i listuje słowa bez image_asset.
// Uruchomienie: dart run tools/find_missing_images.dart

import 'dart:convert';
import 'dart:io';

const _contentDir = 'assets/content/orthography';

void main() {
  final dir = Directory(_contentDir);
  if (!dir.existsSync()) {
    stderr.writeln('Nie znaleziono katalogu $_contentDir');
    exit(1);
  }

  final missingByFile = <String, List<Map<String, String>>>{};
  var totalWords = 0;
  var totalMissing = 0;

  for (final entity in dir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final fileName = entity.uri.pathSegments.last;
    final content = entity.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final words = (json['words'] as List).cast<Map<String, dynamic>>();
    final missing = <Map<String, String>>[];
    for (final w in words) {
      totalWords++;
      final asset = w['image_asset'];
      if (asset == null || (asset is String && asset.isEmpty)) {
        totalMissing++;
        missing.add({
          'id': w['id'] as String,
          'text': w['text'] as String,
          'difficulty': w['difficulty'].toString(),
        });
      }
    }
    if (missing.isNotEmpty) {
      missingByFile[fileName] = missing;
    }
  }

  // Print
  stdout.writeln('# Audyt obrazków — assets/content/orthography/');
  stdout.writeln('');
  stdout.writeln('Łącznie słów: $totalWords');
  stdout.writeln('Bez image_asset: $totalMissing '
      '(${(totalMissing / totalWords * 100).toStringAsFixed(1)}%)');
  stdout.writeln('');

  if (missingByFile.isEmpty) {
    stdout.writeln('🎉 Wszystkie słowa mają obrazek.');
    return;
  }

  for (final entry in missingByFile.entries) {
    stdout.writeln('## ${entry.key} — ${entry.value.length} brakuje');
    stdout.writeln('');
    final sorted = [...entry.value]
      ..sort((a, b) => a['id']!.compareTo(b['id']!));
    for (final w in sorted) {
      stdout.writeln(
          '  - ${w['text']!.padRight(20)} id=${w['id']!.padRight(20)} '
          'diff=${w['difficulty']}');
    }
    stdout.writeln('');
  }

  // Suggestion: list of asset paths to generate
  stdout.writeln('## Lista plików do wygenerowania');
  stdout.writeln('');
  for (final entry in missingByFile.entries) {
    for (final w in entry.value) {
      stdout.writeln('  assets/images/words/${w['id']}.webp');
    }
  }
}
