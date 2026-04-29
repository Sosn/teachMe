// Konwertuje JPG-i z tools/new_images/ do WebP w assets/images/words/
// i dodaje image_asset do odpowiednich słów w JSON-ach.
//
// Użycie:
//   dart run tools/import_new_images.dart            # dry-run
//   dart run tools/import_new_images.dart --apply    # wykonuje
//
// Pomija: niedziela.jpg (wygenerowała się z tekstem, regenerujemy jutro)

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const _srcDir = 'tools/new_images';
const _dstDir = 'assets/images/words';
const _jsonDir = 'assets/content/orthography';
const _cwebpPath = 'tools/webp/cwebp.exe';
const _maxDimension = 512;
const _webpQuality = 90;

const _skipFiles = <String>{};

Future<void> main(List<String> argv) async {
  final apply = argv.contains('--apply');
  if (!apply) {
    stdout.writeln('DRY RUN — nic nie zmienia. Daj --apply.\n');
  }

  final cwebp = File(_cwebpPath).absolute.path;
  if (!File(_cwebpPath).existsSync()) {
    stderr.writeln('BŁĄD: brak $_cwebpPath');
    exit(1);
  }

  final srcDir = Directory(_srcDir);
  final jpgs = srcDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .where((f) => !_skipFiles.contains(f.uri.pathSegments.last))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('Znaleziono ${jpgs.length} plików (po pominięciu '
      '${_skipFiles.length} skipów).');

  // 1. Konwersja każdego do webp
  final converted = <String>{}; // ids that succeeded
  for (final jpg in jpgs) {
    final name = jpg.uri.pathSegments.last.replaceAll('.jpg', '');
    final outWebp = File('$_dstDir/$name.webp');
    stdout.writeln('  $name.jpg → $name.webp');
    if (!apply) {
      converted.add(name);
      continue;
    }

    // Resize to 512×512 max via package:image
    final bytes = jpg.readAsBytesSync();
    final image = img.decodeJpg(bytes);
    if (image == null) {
      stderr.writeln('  ⚠ nie udało się zdekodować $name.jpg, pomijam');
      continue;
    }
    final resized = (image.width > _maxDimension || image.height > _maxDimension)
        ? img.copyResize(
            image,
            width: image.width >= image.height ? _maxDimension : null,
            height: image.height > image.width ? _maxDimension : null,
          )
        : image;

    // Save tmp PNG, run cwebp, delete tmp
    final tmpPng = File('$_dstDir/_tmp_$name.png');
    tmpPng.writeAsBytesSync(img.encodePng(resized));
    final result = Process.runSync(cwebp, [
      '-q', '$_webpQuality',
      '-alpha_q', '100',
      tmpPng.absolute.path,
      '-o', outWebp.absolute.path,
    ]);
    tmpPng.deleteSync();
    if (result.exitCode != 0) {
      stderr.writeln('  ⚠ cwebp failed for $name: ${result.stderr}');
      continue;
    }
    converted.add(name);
  }

  stdout.writeln('\nSkonwertowano ${converted.length} plików.\n');

  // 2. Update JSONs
  final jsonDir = Directory(_jsonDir);
  for (final f in jsonDir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final content = f.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final words = (json['words'] as List).cast<Map<String, dynamic>>();

    var changes = 0;
    for (final w in words) {
      final id = w['id'] as String;
      if (!converted.contains(id)) continue;
      if (w['image_asset'] != null) continue;
      w['image_asset'] = 'assets/images/words/$id.webp';
      changes++;
    }
    if (changes == 0) continue;

    stdout.writeln('${f.uri.pathSegments.last}: $changes słów dostało image_asset');
    if (!apply) continue;

    // Pretty-print preserving order — but jsonEncode sorts keys; we keep
    // simple readable formatting. JSON files are 2-space indent
    // historically; let's match that.
    final encoder = JsonEncoder.withIndent('  ');
    f.writeAsStringSync(encoder.convert(json) + '\n');
  }

  if (!apply) {
    stdout.writeln('\n--- DRY RUN — uruchom z --apply żeby wykonać.');
  } else {
    stdout.writeln('\n✅ Gotowe.');
  }
}
