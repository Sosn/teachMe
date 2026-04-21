import 'package:flutter/material.dart';
import 'package:teach_me/app/theme.dart';

/// Wyświetla słowo z luką (np. "w_z"). Po odpowiedzi można wstawić
/// literę zamiast podkreślenia — rewelacyjny feedback wizualny.
class WordMaskView extends StatelessWidget {
  const WordMaskView({
    required this.mask,
    this.filledLetter,
    this.highlightFilled = false,
    super.key,
  });

  /// Maska postaci "w_z".
  final String mask;

  /// Jeśli ustawione, zamienia `_` na tę literę.
  final String? filledLetter;

  /// Jeśli true, wypełniona litera jest wyróżniona kolorem (po odpowiedzi).
  final bool highlightFilled;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < mask.length; i++) {
      final ch = mask[i];
      if (ch == '_') {
        children.add(_MaskSlot(
          filled: filledLetter,
          highlight: highlightFilled,
        ));
      } else {
        children.add(
          Text(
            ch,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: KidsColors.ink,
              height: 1,
            ),
          ),
        );
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _MaskSlot extends StatelessWidget {
  const _MaskSlot({this.filled, this.highlight = false});

  final String? filled;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (filled == null) {
      return Container(
        width: 56,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: KidsColors.ink.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: highlight ? KidsColors.success : KidsColors.ink,
        height: 1,
      ),
      child: Text(filled!),
    );
  }
}
