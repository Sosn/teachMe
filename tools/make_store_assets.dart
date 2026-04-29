// Generuje assety do uploadu na Play Console:
// 1. App icon 512x512 PNG (foreground + cream bg zmergowany)
// 2. Feature graphic 1024x500 PNG (scale z 2048x1024 Pro)
//
// Użycie: dart run tools/make_store_assets.dart

import 'dart:io';
import 'package:image/image.dart' as img;

const _foregroundPath = 'assets/images/app_icon/jerzy_foreground.png';
const _featureSrcPath = 'assets/images/store/feature_graphic.jpg';
const _iconOutPath = 'assets/images/store/play_icon_512.png';
const _featureOutPath = 'assets/images/store/play_feature_1024x500.png';

// #FFFBF2 — cream, taki sam jak KidsColors.surface i adaptive icon bg.
const _bgR = 0xFF;
const _bgG = 0xFB;
const _bgB = 0xF2;

Future<void> main() async {
  await _makeIcon();
  await _makeFeatureGraphic();
  stdout.writeln('\nGotowe — upload w Play Console → Store listing.');
}

Future<void> _makeIcon() async {
  stdout.writeln('Generuję app icon 512x512...');
  final fg = img.decodeImage(await File(_foregroundPath).readAsBytes());
  if (fg == null) {
    stderr.writeln('Nie mogę wczytać $_foregroundPath');
    exit(1);
  }

  // Canvas 512x512 wypełniony cream.
  final canvas = img.Image(width: 512, height: 512, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(_bgR, _bgG, _bgB, 0xFF));

  // Foreground wrzucamy z 15% insetem (ok. 435px dla safe zone).
  const inset = 40;
  final targetSize = 512 - 2 * inset;
  final fgResized = img.copyResize(
    fg,
    width: targetSize,
    height: targetSize,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    canvas,
    fgResized,
    dstX: inset,
    dstY: inset,
  );

  await File(_iconOutPath).writeAsBytes(img.encodePng(canvas));
  stdout.writeln('  → $_iconOutPath (${canvas.width}x${canvas.height})');
}

Future<void> _makeFeatureGraphic() async {
  stdout.writeln('Generuję feature graphic 1024x500...');
  final src = img.decodeImage(await File(_featureSrcPath).readAsBytes());
  if (src == null) {
    stderr.writeln('Nie mogę wczytać $_featureSrcPath');
    exit(1);
  }

  // Resize do 1024x500 (Play Console wymaga dokładnie tego rozmiaru).
  final scaled = img.copyResize(
    src,
    width: 1024,
    height: 500,
    interpolation: img.Interpolation.cubic,
  );

  await File(_featureOutPath).writeAsBytes(img.encodePng(scaled));
  stdout.writeln('  → $_featureOutPath (${scaled.width}x${scaled.height})');
}
