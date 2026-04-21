import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/exercise/session_state.dart';

/// Wariant ćwiczenia: **znajdź błąd w zdaniu**.
///
/// Pedagogicznie najbardziej wartościowy typ — trenuje rozpoznawanie
/// błędu w kontekście (jak w czytaniu własnych wypracowań), a nie
/// tylko wybór między dwoma wariantami. Dziecko widzi zdanie (≥5 słów)
/// z jednym słowem przekręconym ortograficznie (correct ↔ distractor)
/// i tapuje błędne słowo.
///
/// Działa tylko na słowach z `exampleSentence`. SessionController
/// ogranicza ten typ do meta-kategorii `findError`.
class FindErrorExercise extends ConsumerStatefulWidget {
  const FindErrorExercise({required this.state, super.key});

  final SessionActive state;

  @override
  ConsumerState<FindErrorExercise> createState() => _FindErrorExerciseState();
}

class _FindErrorExerciseState extends ConsumerState<FindErrorExercise> {
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    final word = widget.state.currentWord;
    final sentence = word.exampleSentence;
    if (sentence == null) {
      // Nie powinno się zdarzyć — repository filtruje, ale safety.
      return const _MissingSentenceFallback();
    }

    final rawErrorized = _errorize(word);
    // Zamieniamy wystąpienie word.text w zdaniu na błędną wersję.
    // Obsługujemy też wariant capitalized (gdy zdanie zaczyna się od
    // word.text z wielkiej litery) — inaczej replaceFirst by nic nie
    // podmienił i dziecko dostałoby zdanie bez błędu.
    final capText = _capitalize(word.text);
    final capErrorized = _capitalize(rawErrorized);
    final String displayed;
    final String errorized;
    if (sentence.contains(word.text)) {
      displayed = sentence.replaceFirst(word.text, rawErrorized);
      errorized = rawErrorized;
    } else if (sentence.contains(capText)) {
      displayed = sentence.replaceFirst(capText, capErrorized);
      errorized = capErrorized;
    } else {
      // Awaryjnie: ani mała ani wielka forma w zdaniu — pokazujemy
      // niezmienione zdanie (treść zadania i tak jest zgłoszeniem buga).
      displayed = sentence;
      errorized = rawErrorized;
    }

    // Tokenizacja — tokeny mogą zawierać interpunkcję (.,?!).
    final tokens = displayed.split(' ');
    final errorIndex = _findErrorIndex(tokens, errorized);

    final answered = widget.state.isAnswered;
    final lastCorrect = widget.state.lastAnswerCorrect ?? false;
    final imageHeight = MediaQuery.of(context).size.height * 0.18;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Pytanie ${widget.state.currentIndex + 1} z ${widget.state.words.length}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Znajdź błąd — kliknij słowo napisane źle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.85),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        if (word.imageAsset != null)
          SizedBox(
            height: imageHeight,
            child: Image.asset(word.imageAsset!, fit: BoxFit.contain),
          ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 10,
          children: [
            for (var i = 0; i < tokens.length; i++)
              _TokenChip(
                token: tokens[i],
                isError: i == errorIndex,
                tapped: _tappedIndex == i,
                answered: answered,
                onTap: answered
                    ? null
                    : () => _onTap(i, i == errorIndex, word),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (answered) _Feedback(word: word, lastCorrect: lastCorrect),
      ],
    );
  }

  /// Tworzy wersję z błędem. Jeśli JSON dostarcza ręcznie napisany
  /// `errorized` (naturalniejszy błąd dziecięcy) — używamy go.
  /// Inaczej mechaniczna zamiana pierwszego wystąpienia `correct`
  /// na `distractor` (np. "nóż" → "nuż").
  String _errorize(Word word) {
    final manual = word.errorized;
    if (manual != null && manual.isNotEmpty) return manual;
    return word.text.replaceFirst(word.correct, word.distractor);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  int? _findErrorIndex(List<String> tokens, String errorized) {
    for (var i = 0; i < tokens.length; i++) {
      final stripped = _stripPunctuation(tokens[i]);
      if (stripped == errorized) return i;
    }
    return null;
  }

  String _stripPunctuation(String s) =>
      s.replaceAll(RegExp('[.,!?;:]'), '');

  void _onTap(int index, bool isError, Word word) {
    setState(() => _tappedIndex = index);
    unawaited(
      ref.read(exerciseSessionProvider.notifier).answer(
            isError ? word.correct : word.distractor,
          ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.token,
    required this.isError,
    required this.tapped,
    required this.answered,
    required this.onTap,
  });

  final String token;
  final bool isError;
  final bool tapped;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors();
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      elevation: tapped ? 3 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: tapped ? 2.5 : 1.5),
          ),
          child: Text(
            token,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color border) _colors() {
    if (!answered) {
      return (
        Colors.white.withValues(alpha: 0.85),
        KidsColors.ink,
        KidsColors.ink.withValues(alpha: 0.25),
      );
    }
    if (isError) {
      // Po odpowiedzi zawsze pokazujemy gdzie był błąd na czerwono.
      return (
        KidsColors.warn.withValues(alpha: 0.15),
        KidsColors.warn,
        KidsColors.warn,
      );
    }
    if (tapped) {
      // Gracz tapnął non-error słowo = źle odpowiedział.
      return (
        KidsColors.warn.withValues(alpha: 0.08),
        KidsColors.ink,
        KidsColors.warn.withValues(alpha: 0.6),
      );
    }
    return (
      Colors.white.withValues(alpha: 0.6),
      KidsColors.ink.withValues(alpha: 0.55),
      KidsColors.ink.withValues(alpha: 0.15),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.word, required this.lastCorrect});

  final Word word;
  final bool lastCorrect;

  @override
  Widget build(BuildContext context) {
    final text = lastCorrect
        ? 'Brawo! Poprawnie pisze się ${word.text}. ${word.exampleHint}'
        : 'Błąd był tutaj. Poprawnie pisze się ${word.text}. ${word.exampleHint}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: KidsColors.ink.withValues(alpha: 0.9),
          height: 1.3,
        ),
      ),
    );
  }
}

class _MissingSentenceFallback extends StatelessWidget {
  const _MissingSentenceFallback();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'To pytanie nie ma przygotowanego zdania. Przejdź do następnego.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
