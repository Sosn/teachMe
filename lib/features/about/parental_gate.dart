import 'dart:math';

import 'package:flutter/material.dart';
import 'package:teach_me/app/theme.dart';

/// Parental gate — dialog z pytaniem matematycznym, które odpowie tylko
/// osoba dorosła (lub uczeń klasy 5+). Google Play "Designed for Families"
/// wymaga takiego mechanizmu przed każdą akcją wychodzącą z aplikacji
/// (linki zewnętrzne, płatności, kontakt e-mail).
///
/// Zadanie: mnożenie dwucyfrowych liczb (np. 17 × 13). Dla klasy 3-4 to
/// wyzwanie (wynik jest trzycyfrowy, wymaga kartki i ołówka albo dłuższej
/// koncentracji), dla dorosłego 10 sekund w pamięci.
///
/// Zwraca `true` gdy użytkownik wybrał poprawną odpowiedź, `false` przy
/// błędzie / zamknięciu dialogu.
class ParentalGate {
  ParentalGate._();

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ParentalGateDialog(),
    );
    return result ?? false;
  }
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  late final int _a;
  late final int _b;
  late final int _correct;
  late final List<int> _options;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 11 + rng.nextInt(19); // 11..29
    _b = 11 + rng.nextInt(19); // 11..29
    _correct = _a * _b;
    // 3 opcje: poprawna + 2 dystraktory blisko ale odróżnialne.
    final distractors = <int>{};
    while (distractors.length < 2) {
      final delta = (rng.nextInt(40) - 20).abs() + 7; // 7..27
      final sign = rng.nextBool() ? 1 : -1;
      final candidate = _correct + sign * delta;
      if (candidate != _correct && candidate > 0) {
        distractors.add(candidate);
      }
    }
    _options = [_correct, ...distractors]..shuffle(rng);
  }

  void _onAnswer(int answer) {
    Navigator.of(context).pop(answer == _correct);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tylko dla dorosłych'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aby kontynuować, rozwiąż poniższe działanie:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$_a × $_b = ?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: KidsColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _onAnswer(option),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text('$option'),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
      ],
    );
  }
}
