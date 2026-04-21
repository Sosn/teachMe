import 'package:flutter/material.dart';

/// Dostępne sceny tła — enum zamiast magic stringów.
enum SceneBackground {
  menu('assets/images/background/bg_menu.png'),
  exercise('assets/images/background/bg_exercise.png'),
  summary('assets/images/background/bg_summary.png');

  const SceneBackground(this.asset);
  final String asset;
}

/// Full-bleed tło ekranu. Obraz jest "covered" (wypełnia cały ekran bez
/// deformacji), a dzieci nie widzą pustych pasów. Nad obrazem jest
/// subtelna biała warstwa [overlayOpacity] — daje czytelność dla treści,
/// jeśli tło jest za jaskrawe.
class SceneBackdrop extends StatelessWidget {
  const SceneBackdrop({
    required this.scene,
    required this.child,
    this.overlayOpacity = 0,
    super.key,
  });

  final SceneBackground scene;
  final Widget child;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(scene.asset),
          fit: BoxFit.cover,
        ),
      ),
      child: overlayOpacity > 0
          ? ColoredBox(
              color: Colors.white.withValues(alpha: overlayOpacity),
              child: child,
            )
          : child,
    );
  }
}
