import 'package:flutter/material.dart';
import 'package:teach_me/features/mascot/mascot_mood.dart';

/// Wyświetla pluszowego jeża w wybranym nastroju. Animowane przejście
/// między stanami — dziecko widzi "żywą" maskotkę, nie statyczny obrazek.
class MascotView extends StatelessWidget {
  const MascotView({
    required this.mood,
    this.size = 160,
    super.key,
  });

  final MascotMood mood;
  final double size;

  String get _assetPath => switch (mood) {
        MascotMood.neutral => 'assets/images/mascot/hedgehog_neutral.png',
        MascotMood.happy => 'assets/images/mascot/hedgehog_happy.png',
        MascotMood.sad => 'assets/images/mascot/hedgehog_sad.png',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      child: Image.asset(
        _assetPath,
        key: ValueKey(mood),
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
