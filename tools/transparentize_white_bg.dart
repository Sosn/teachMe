// Wykrywa obrazki z białym tłem w assets/images/words/ i zamienia tło
// na przezroczyste przez flood-fill od krawędzi. Wewnętrzne białe miejsca
// (lukier ciasta, śnieg, białe ubrania, brzuch jeża) zostają — bo nie są
// połączone z krawędzią.
//
// Algorytm:
//  1. Wczytaj WebP, skonwertuj do RGBA.
//  2. Sprawdź 4 piksele narożne. Jeśli już mają alpha=0 → pomiń (transparent).
//     Jeśli żaden nie jest „białawy" (min RGB > 230) → pomiń (kolorowe tło).
//  3. BFS od pikseli krawędziowych białawych.
//     Dla każdego napotkanego piksela ustaw alpha na podstawie „białości":
//       min RGB == 255 → alpha 0 (pure white)
//       min RGB ∈ [200, 255) → liniowo (255 → 0)
//       min RGB < 200 → alpha 255 (subject, zatrzymujemy flood-fill).
//  4. Zapisz tymczasowy PNG → cwebp → nadpisz oryginalny .webp.
//
// Użycie:
//   dart run tools/transparentize_white_bg.dart            # dry-run
//   dart run tools/transparentize_white_bg.dart --apply    # wykonuje

import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _wordsDir = 'assets/images/words';
const _cwebpPath = 'tools/webp/cwebp.exe';
const _webpQuality = 90;

// Tunables.
const int _whiteMin = 220; // min RGB >= this → kandydat na tło
const int _subjectMin = 200; // min RGB < this → na pewno subject (stop flood)
const int _fullyWhite = 240; // min RGB >= this → fully transparent (alpha 0)
// Pomiędzy [_subjectMin, _fullyWhite] alpha jest interpolowana liniowo.
// Wartość 240 (zamiast 255) tnie też cream/paper texture na tle.

int _alphaForMinRgb(int minRgb) {
  if (minRgb >= _fullyWhite) return 0;
  if (minRgb < _subjectMin) return 255;
  final t = (minRgb - _subjectMin) / (_fullyWhite - _subjectMin);
  return (255 * (1 - t)).round().clamp(0, 255);
}

bool _isWhitish(img.Pixel p) {
  final minRgb = math.min(p.r, math.min(p.g, p.b)).toInt();
  return minRgb >= _whiteMin;
}

bool _alreadyTransparent(img.Image image) {
  // 4 narożniki — jeśli wszystkie mają alpha=0, obrazek już zrobiony.
  if (image.numChannels < 4) return false;
  final w = image.width;
  final h = image.height;
  final corners = [
    image.getPixel(0, 0),
    image.getPixel(w - 1, 0),
    image.getPixel(0, h - 1),
    image.getPixel(w - 1, h - 1),
  ];
  return corners.every((p) => p.a.toInt() == 0);
}

bool _hasWhiteEdge(img.Image image) {
  // Sprawdź środki 4 krawędzi — czy któryś jest białawy?
  final w = image.width;
  final h = image.height;
  final samples = [
    image.getPixel(w ~/ 2, 0),
    image.getPixel(w ~/ 2, h - 1),
    image.getPixel(0, h ~/ 2),
    image.getPixel(w - 1, h ~/ 2),
  ];
  return samples.any(_isWhitish);
}

img.Image _floodFillTransparent(img.Image src) {
  final image = src.numChannels == 4 ? src : src.convert(numChannels: 4);
  final w = image.width;
  final h = image.height;
  final visited = List<bool>.filled(w * h, false);
  final queue = Queue<int>();

  // Seed: wszystkie piksele krawędziowe białawe.
  void seed(int x, int y) {
    final p = image.getPixel(x, y);
    if (_isWhitish(p)) {
      final idx = y * w + x;
      if (!visited[idx]) {
        visited[idx] = true;
        queue.add(idx);
      }
    }
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }

  // BFS.
  while (queue.isNotEmpty) {
    final idx = queue.removeFirst();
    final x = idx % w;
    final y = idx ~/ w;
    final p = image.getPixel(x, y);
    final minRgb = math.min(p.r, math.min(p.g, p.b)).toInt();
    final alpha = _alphaForMinRgb(minRgb);
    p.setRgba(p.r, p.g, p.b, alpha);

    // Rozszerzaj BFS tylko jeśli alpha == 0 (pełne tło) lub jest blisko
    // (alpha < 200). To zatrzymuje flood na "twardych" krawędziach
    // koloru, ale przepuszcza miękkie watercolor edges.
    if (alpha < 200) {
      const dx = [1, -1, 0, 0];
      const dy = [0, 0, 1, -1];
      for (var i = 0; i < 4; i++) {
        final nx = x + dx[i];
        final ny = y + dy[i];
        if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
        final nIdx = ny * w + nx;
        if (visited[nIdx]) continue;
        final np = image.getPixel(nx, ny);
        final nMinRgb = math.min(np.r, math.min(np.g, np.b)).toInt();
        if (nMinRgb >= _subjectMin) {
          visited[nIdx] = true;
          queue.add(nIdx);
        }
      }
    }
  }

  return image;
}

Future<bool> _processFile(File webp, {required bool apply}) async {
  final bytes = webp.readAsBytesSync();
  final image = img.decodeWebP(bytes);
  if (image == null) {
    stderr.writeln('  ⚠ decode failed: ${webp.path}');
    return false;
  }

  if (_alreadyTransparent(image)) {
    return false; // skip
  }
  if (!_hasWhiteEdge(image)) {
    return false; // colored bg, not white
  }

  if (!apply) return true;

  // Apply flood-fill.
  final transparent = _floodFillTransparent(image);

  // Tmp PNG → cwebp → overwrite.
  final name = webp.uri.pathSegments.last.replaceAll('.webp', '');
  final tmpPng = File('$_wordsDir/_tmp_bg_$name.png');
  tmpPng.writeAsBytesSync(img.encodePng(transparent));
  final result = Process.runSync(File(_cwebpPath).absolute.path, [
    '-q', '$_webpQuality',
    '-alpha_q', '100',
    tmpPng.absolute.path,
    '-o', webp.absolute.path,
  ]);
  tmpPng.deleteSync();
  if (result.exitCode != 0) {
    stderr.writeln('  ⚠ cwebp failed for $name');
    return false;
  }
  return true;
}

Future<void> main(List<String> argv) async {
  final apply = argv.contains('--apply');
  if (!apply) stdout.writeln('DRY RUN — daj --apply żeby wykonać.\n');

  if (!File(_cwebpPath).existsSync()) {
    stderr.writeln('BŁĄD: brak $_cwebpPath');
    exit(1);
  }

  final dir = Directory(_wordsDir);
  final webps = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.webp'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('Plików .webp w $_wordsDir: ${webps.length}');

  var skippedTransparent = 0;
  var skippedColored = 0;
  final candidates = <File>[];

  for (final f in webps) {
    final bytes = f.readAsBytesSync();
    final image = img.decodeWebP(bytes);
    if (image == null) continue;
    if (_alreadyTransparent(image)) {
      skippedTransparent++;
      continue;
    }
    if (!_hasWhiteEdge(image)) {
      skippedColored++;
      continue;
    }
    candidates.add(f);
  }

  stdout.writeln('  - już przezroczyste: $skippedTransparent');
  stdout.writeln('  - kolorowe tło (pomijam): $skippedColored');
  stdout.writeln('  - z białym tłem do przerobienia: ${candidates.length}\n');

  if (candidates.isEmpty) {
    stdout.writeln('Nic do roboty.');
    return;
  }

  if (!apply) {
    for (final f in candidates) {
      stdout.writeln('  ${f.uri.pathSegments.last}');
    }
    stdout.writeln('\n--- DRY RUN — uruchom z --apply żeby wykonać.');
    return;
  }

  var processed = 0;
  for (final f in candidates) {
    final name = f.uri.pathSegments.last;
    stdout.write('  $name ... ');
    final ok = await _processFile(f, apply: true);
    if (ok) {
      processed++;
      stdout.writeln('✓');
    } else {
      stdout.writeln('skip');
    }
  }

  stdout.writeln('\n✅ Zrobione: $processed plików.');
}
