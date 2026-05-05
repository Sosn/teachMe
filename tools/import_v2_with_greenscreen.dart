// One-shot pipeline dla obrazków v2 wygenerowanych z greenscreenem:
// 1. Wczytaj JPG z tools/new_images_v2/
// 2. Usuń zielony kanał (chroma key) → transparent PNG
// 3. Resize do 512×512
// 4. Konwersja PNG → WebP via cwebp -alpha_q 100
// 5. Nadpisz istniejący webp w assets/images/words/
//
// Użycie:
//   dart run tools/import_v2_with_greenscreen.dart            # dry-run
//   dart run tools/import_v2_with_greenscreen.dart --apply    # wykonuje

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _srcDir = 'tools/new_images_v2';
const _dstDir = 'assets/images/words';
const _cwebpPath = 'tools/webp/cwebp.exe';
const _maxDimension = 512;
const _webpQuality = 90;

// Greenscreen tunables (skopiowane z remove_greenscreen.dart).
const double _fullyTransparent = 50;
const double _startEdge = 10;

int _alphaFor(double greenDom) {
  if (greenDom >= _fullyTransparent) return 0;
  if (greenDom <= _startEdge) return 255;
  final t = (greenDom - _startEdge) / (_fullyTransparent - _startEdge);
  return (255 * (1 - t)).round().clamp(0, 255);
}

img.Image _removeGreenscreen(img.Image src) {
  final out = src.numChannels == 4 ? src : src.convert(numChannels: 4);
  for (final p in out) {
    if (p.a.toInt() == 0) continue;
    final r = p.r.toDouble();
    final g = p.g.toDouble();
    final b = p.b.toDouble();
    final greenDom = g - math.max(r, b);
    final alpha = _alphaFor(greenDom);
    if (alpha == 255) continue;
    final despilledG = math.max(r, b);
    p.setRgba(r.round(), despilledG.round(), b.round(), alpha);
  }
  return out;
}

Future<void> main(List<String> argv) async {
  final apply = argv.contains('--apply');
  if (!apply) stdout.writeln('DRY RUN — daj --apply żeby wykonać.\n');

  final cwebp = File(_cwebpPath).absolute.path;
  if (!File(_cwebpPath).existsSync()) {
    stderr.writeln('BŁĄD: brak $_cwebpPath');
    exit(1);
  }

  final src = Directory(_srcDir);
  if (!src.existsSync()) {
    stderr.writeln('BŁĄD: brak $_srcDir');
    exit(1);
  }

  final jpgs = src
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('Plików do obróbki: ${jpgs.length}\n');

  for (final jpg in jpgs) {
    final name = jpg.uri.pathSegments.last.replaceAll('.jpg', '');
    final outWebp = File('$_dstDir/$name.webp');
    final overwriting = outWebp.existsSync() ? ' (NADPISZE)' : '';
    stdout.writeln('  $name.jpg → $name.webp$overwriting');
    if (!apply) continue;

    // 1. decode JPG
    final image = img.decodeJpg(jpg.readAsBytesSync());
    if (image == null) {
      stderr.writeln('    ⚠ decode failed');
      continue;
    }

    // 2. remove greenscreen
    final transparent = _removeGreenscreen(image);

    // 3. resize
    final resized = (transparent.width > _maxDimension ||
            transparent.height > _maxDimension)
        ? img.copyResize(
            transparent,
            width: transparent.width >= transparent.height
                ? _maxDimension
                : null,
            height: transparent.height > transparent.width
                ? _maxDimension
                : null,
          )
        : transparent;

    // 4. save as transparent PNG (tmp), run cwebp, delete tmp
    final tmpPng = File('$_dstDir/_tmp_v2_$name.png');
    tmpPng.writeAsBytesSync(img.encodePng(resized));
    final result = Process.runSync(cwebp, [
      '-q', '$_webpQuality',
      '-alpha_q', '100', // alpha lossless — kluczowe dla watercolor edges
      tmpPng.absolute.path,
      '-o', outWebp.absolute.path,
    ]);
    tmpPng.deleteSync();

    if (result.exitCode != 0) {
      stderr.writeln('    ⚠ cwebp failed: ${result.stderr}');
      continue;
    }
    final size = outWebp.lengthSync();
    stdout.writeln('    ✓ ${(size / 1024).toStringAsFixed(1)} KB');
  }

  stdout.writeln(
    '\n${apply ? "Gotowe." : "DRY RUN — uruchom z --apply żeby wykonać."}',
  );
}
