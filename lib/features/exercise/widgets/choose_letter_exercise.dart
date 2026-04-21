import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/exercise/session_state.dart';
import 'package:teach_me/features/exercise/widgets/letter_button.dart';
import 'package:teach_me/features/exercise/widgets/word_mask_view.dart';

/// Widget pojedynczego pytania "wybierz literę".
///
/// Układ pionowy:
/// 1. licznik "Pytanie X z Y"
/// 2. obrazek słowa (~25% wysokości ekranu, tylko jeśli słowo go ma)
/// 3. słowo z luką (maska)
/// 4. dwa duże przyciski literowe
/// 5. podpowiedź po odpowiedzi (reguła + przykład)
///
/// Przycisk "Dalej →" NIE jest tutaj — wyświetla go parent screen
/// jako floating po prawej stronie.
class ChooseLetterExercise extends ConsumerWidget {
  const ChooseLetterExercise({required this.state, super.key});

  final SessionActive state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = state.currentWord;
    final answered = state.isAnswered;
    final lastCorrect = state.lastAnswerCorrect;
    final selectedLetter =
        answered ? state.attempts.last.selectedLetter : null;
    final imageHeight = MediaQuery.of(context).size.height * 0.25;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Pytanie ${state.currentIndex + 1} z ${state.words.length}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // Neutralne — „litera" myli dla dwuznaków (rz, sz, ch) i sekwencji
          // nosówkowych (om, on) obecnych w JSON-ach.
          'Wybierz, co pasuje',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        _WordImage(imageAsset: word.imageAsset, height: imageHeight),
        const SizedBox(height: 16),
        WordMaskView(
          mask: word.mask,
          filledLetter: answered ? word.correct : null,
          highlightFilled: answered && (lastCorrect ?? false),
        ),
        const SizedBox(height: 24),
        _LetterRow(
          word: word,
          answered: answered,
          selectedLetter: selectedLetter,
          lastCorrect: lastCorrect,
          onPick: (letter) =>
              ref.read(exerciseSessionProvider.notifier).answer(letter),
        ),
        const SizedBox(height: 16),
        if (answered)
          _FeedbackHint(
            correct: lastCorrect ?? false,
            hint: word.exampleHint,
            ruleHint: word.rule.hint,
          ),
      ],
    );
  }
}

/// Obrazek słowa (jeśli dostępny). Gdy słowo nie ma obrazka — pusta
/// przestrzeń w tym samym wymiarze, żeby layout nie skakał.
class _WordImage extends StatelessWidget {
  const _WordImage({required this.imageAsset, required this.height});

  final String? imageAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null) {
      // Bez obrazka oddajemy mniej miejsca, żeby karta nie była olbrzymia.
      return SizedBox(height: height * 0.6);
    }
    return SizedBox(
      height: height,
      child: Image.asset(imageAsset!, fit: BoxFit.contain),
    );
  }
}

class _LetterRow extends StatelessWidget {
  const _LetterRow({
    required this.word,
    required this.answered,
    required this.selectedLetter,
    required this.lastCorrect,
    required this.onPick,
  });

  final Word word;
  final bool answered;
  final String? selectedLetter;
  final bool? lastCorrect;
  final void Function(String letter) onPick;

  LetterButtonState _stateFor(String letter) {
    if (!answered) return LetterButtonState.idle;
    if (letter == selectedLetter) {
      return (lastCorrect ?? false)
          ? LetterButtonState.correct
          : LetterButtonState.wrong;
    }
    if (letter == word.correct && !(lastCorrect ?? false)) {
      return LetterButtonState.correct;
    }
    return LetterButtonState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    // Stabilna, pseudolosowa kolejność — nie zawsze poprawna z lewej.
    final correctFirst = word.id.hashCode.isEven;
    final letters = correctFirst
        ? [word.correct, word.distractor]
        : [word.distractor, word.correct];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LetterButton(
          letter: letters[0],
          state: _stateFor(letters[0]),
          onPressed: () => onPick(letters[0]),
        ),
        const SizedBox(width: 24),
        LetterButton(
          letter: letters[1],
          state: _stateFor(letters[1]),
          onPressed: () => onPick(letters[1]),
        ),
      ],
    );
  }
}

class _FeedbackHint extends StatelessWidget {
  const _FeedbackHint({
    required this.correct,
    required this.hint,
    required this.ruleHint,
  });

  final bool correct;
  final String hint;
  final String ruleHint;

  @override
  Widget build(BuildContext context) {
    final text = correct ? hint : '$ruleHint\n$hint';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: KidsColors.ink.withValues(alpha: 0.85),
          height: 1.3,
        ),
      ),
    );
  }
}
