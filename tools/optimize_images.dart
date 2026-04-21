// Optymalizacja obrazków asetowych przed publikacją.
//
// Co robi:
// 1. Czyta wszystkie .png z `assets/images/words/`
// 2. Skaluje do max 512×512 (jeśli większe) — watercolorowe obrazki są
//    1024×1024, w UI mobilnym wyświetlane są ~150-300px. 512 daje bufor
//    na tablety i HD-ready, bez widocznej utraty jakości.
// 3. Zapisuje tymczasowy PNG
// 4. Wywołuje `tools/webp/cwebp.exe -q 90 -alpha_q 100 in.png -o out.webp`
//    (quality 90 + alpha lossless — dla watercolor ultra-cienkich krawędzi
//    nie chcemy kompresować alpha channel'u)
// 5. Usuwa tymczasowy PNG
// 6. Usuwa oryginalny .png
// 7. Po wszystkim aktualizuje JSON-y: `image_asset: "...png"` → `"...webp"`
//
// Użycie:
//   dart run tools/optimize_images.dart            # dry-run (pokazuje co by zrobił)
//   dart run tools/optimize_images.dart --apply    # wykonuje
//
// Uwaga: to jest operacja destrukcyjna. Rób git commit przed uruchomieniem.

import 'dart:io';

import 'package:image/image.dart' as img;

const _wordsDir = 'assets/images/words';
const _jsonDir = 'assets/content/orthography';
const _cwebpPath = 'tools/webp/cwebp.exe';
const _maxDimension = 512;
const _webpQuality = 90;

Future<void> main(List<String> argv) async {
  final apply = argv.contains('--apply');
  if (!apply) {
    stdout.writeln('DRY RUN — nic nie zmienia. Daj --apply żeby wykonać.');
  }

  // Sanity check: cwebp musi istnieć.
  final cwebp = File(_cwebpPath);
  if (!cwebp.existsSync()) {
    stderr.writeln('BŁĄD: nie znaleziono $_cwebpPath');
    stderr.writeln('Pobierz cwebp.exe z https://developers.google.com/speed/webp/download');
    stderr.writeln('i wklej do $_cwebpPath');
    exit(1);
  }

  final wordsDir = Directory(_wordsDir);
  if (!wordsDir.existsSync()) {
    stderr.writeln('BŁĄD: nie znaleziono katalogu $_wordsDir');
    exit(1);
  }

  final pngs = await wordsDir
      .list()
      .where((e) => e is File && e.path.toLowerCase().endsWith('.png'))
      .cast<File>()
      .toList();
  stdout.writeln('Znaleziono ${pngs.length} plików .png');

  var totalBefore = 0;
  var totalAfter = 0;
  var processed = 0;
  var skipped = 0;
  final converted = <String, String>{}; // old -> new path

  for (final src in pngs) {
    final srcSize = src.lengthSync();
    totalBefore += srcSize;
    final baseName = src.uri.pathSegments.last.replaceAll('.png', '');
    final tempResized = File('${src.parent.path}/_tmp_$baseName.png');
    final outWebp = File('${src.parent.path}/$baseName.webp');

    // 1) Decode, resize jeśli trzeba, zapisz jako temp PNG.
    final bytes = await src.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      stderr.writeln('SKIP (decode failed): ${src.path}');
      skipped++;
      continue;
    }

    img.Image resized;
    if (image.width > _maxDimension || image.height > _maxDimension) {
      resized = img.copyResize(
        image,
        width: image.width >= image.height ? _maxDimension : null,
        height: image.height > image.width ? _maxDimension : null,
        interpolation: img.Interpolation.cubic,
      );
    } else {
      resized = image;
    }

    if (!apply) {
      stdout.writeln(
        '${src.uri.pathSegments.last}  ${image.width}x${image.height} '
        '(${_fmt(srcSize)})  -->  ${resized.width}x${resized.height} .webp',
      );
      processed++;
      continue;
    }

    await tempResized.writeAsBytes(img.encodePng(resized));

    // 2) cwebp temp.png -> out.webp
    // Windows Process.run wymaga absolute path do exe.
    final cwebpAbs = File(_cwebpPath).absolute.path;
    final result = await Process.run(
      cwebpAbs,
      [
        '-q', '$_webpQuality',
        '-alpha_q', '100', // alpha lossless
        '-quiet',
        tempResized.absolute.path,
        '-o', outWebp.absolute.path,
      ],
    );

    await tempResized.delete();

    if (result.exitCode != 0) {
      stderr.writeln('BŁĄD cwebp dla ${src.path}:');
      stderr.writeln(result.stderr);
      skipped++;
      continue;
    }

    final outSize = outWebp.lengthSync();
    totalAfter += outSize;

    // 3) Usuń oryginalny PNG.
    await src.delete();
    converted['$_wordsDir/$baseName.png'] = '$_wordsDir/$baseName.webp';

    stdout.writeln(
      '${src.uri.pathSegments.last}: ${_fmt(srcSize)} -> ${_fmt(outSize)} '
      '(${((1 - outSize / srcSize) * 100).toStringAsFixed(0)}% mniej)',
    );
    processed++;
  }

  // 4) Aktualizacja JSON-ów.
  if (apply && converted.isNotEmpty) {
    stdout.writeln('\nAktualizuję JSON-y w $_jsonDir ...');
    final jsonFiles = await Directory(_jsonDir)
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    for (final jf in jsonFiles) {
      final content = await jf.readAsString();
      // [^"/]+ łapie też polskie znaki w nazwach plików (np. pisklę.png).
      final updated = content.replaceAllMapped(
        RegExp(r'"assets/images/words/([^"/]+)\.png"'),
        (m) => '"assets/images/words/${m.group(1)}.webp"',
      );
      if (updated != content) {
        await jf.writeAsString(updated);
        stdout.writeln('  updated ${jf.uri.pathSegments.last}');
      }
    }
  }

  stdout.writeln('\n=== Podsumowanie ===');
  stdout.writeln('Przetworzone: $processed');
  stdout.writeln('Pominięte:    $skipped');
  if (apply) {
    final saved = totalBefore - totalAfter;
    final pct = totalBefore == 0
        ? 0
        : ((1 - totalAfter / totalBefore) * 100).toStringAsFixed(1);
    stdout.writeln('Przed: ${_fmt(totalBefore)}');
    stdout.writeln('Po:    ${_fmt(totalAfter)}');
    stdout.writeln('Zysk:  ${_fmt(saved)} ($pct%)');
  } else {
    stdout.writeln('(dry-run — uruchom z --apply żeby wykonać)');
  }
}

String _fmt(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
