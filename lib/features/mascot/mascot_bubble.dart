import 'package:flutter/material.dart';
import 'package:teach_me/app/theme.dart';

/// Dymek wypowiedzi obok maskotki. Zaokrąglony, duża czcionka,
/// przyjazny dla dzieci.
class MascotBubble extends StatelessWidget {
  const MascotBubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KidsColors.seed.withValues(alpha: 0.25), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: KidsColors.ink,
        ),
      ),
    );
  }
}
