import 'package:flutter/material.dart';
import 'package:teach_me/app/theme.dart';

/// Duży, zaokrąglony przycisk z pojedynczą literą. Używany w ćwiczeniach
/// typu "wybierz literę". Wizualnie reaguje na wybór (correct/wrong) —
/// po kliknięciu zmienia kolor na zielony/pomarańczowy i blokuje
/// dalsze kliknięcia.
class LetterButton extends StatelessWidget {
  const LetterButton({
    required this.letter,
    required this.onPressed,
    this.state = LetterButtonState.idle,
    super.key,
  });

  final String letter;
  final VoidCallback? onPressed;
  final LetterButtonState state;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForState(state);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.bg.withValues(alpha: 0.35),
            blurRadius: state == LetterButtonState.idle ? 10 : 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state == LetterButtonState.idle ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: 128,
            height: 128,
            child: Center(
              // FittedBox: "ś" pozostaje 72 px, multi-char "si"/"ci" sam
              // się przeskaluje żeby się zmieścić w kwadracie.
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: colors.fg,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _LetterColors _colorsForState(LetterButtonState s) {
    switch (s) {
      case LetterButtonState.idle:
        return const _LetterColors(KidsColors.seed, Colors.white);
      case LetterButtonState.correct:
        return const _LetterColors(KidsColors.success, Colors.white);
      case LetterButtonState.wrong:
        return const _LetterColors(KidsColors.warn, Colors.white);
      case LetterButtonState.disabled:
        return _LetterColors(
          KidsColors.seed.withValues(alpha: 0.3),
          Colors.white,
        );
    }
  }
}

enum LetterButtonState { idle, correct, wrong, disabled }

class _LetterColors {
  const _LetterColors(this.bg, this.fg);
  final Color bg;
  final Color fg;
}
