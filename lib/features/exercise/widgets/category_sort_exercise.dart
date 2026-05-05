import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/exercise/session_state.dart';

/// Wariant ćwiczenia: worki kategorii.
///
/// Dziecko widzi słowo z luką i dwa worki (np. "ó", "u"). Przeciąga
/// cały wyraz do właściwego worka. Różnica względem drag-letter:
/// tutaj sygnał pedagogiczny jest o **kategoryzacji wg reguły**, nie
/// wstawianiu litery — dziecko musi stwierdzić "to słowo należy do
/// rodziny ó", a nie "tu wstawiam ó".
class CategorySortExercise extends ConsumerWidget {
  const CategorySortExercise({required this.state, super.key});

  final SessionActive state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = state.currentWord;
    final answered = state.isAnswered;
    final lastCorrect = state.lastAnswerCorrect;
    final imageHeight = MediaQuery.of(context).size.height * 0.22;

    // Worki ułożone stabilnie (id jako seed parzystości) — nie zawsze
    // poprawna z lewej.
    final correctLeft = word.id.hashCode.isEven;
    final bucketsLetters = correctLeft
        ? [word.correct, word.distractor]
        : [word.distractor, word.correct];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Pytanie ${state.currentIndex + 1} z ${state.words.length}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Do którego worka należy to słowo?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        _WordImage(imageAsset: word.imageAsset, height: imageHeight),
        const SizedBox(height: 14),
        _WordDraggable(word: word, answered: answered, lastCorrect: lastCorrect),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final letter in bucketsLetters)
              _Bucket(
                letter: letter,
                answered: answered,
                showCorrectGlow:
                    answered && letter == word.correct,
                onAccept: () => ref
                    .read(exerciseSessionProvider.notifier)
                    .answer(letter),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (answered) _FeedbackHint(word: word, correct: lastCorrect ?? false),
      ],
    );
  }
}

class _WordImage extends StatelessWidget {
  const _WordImage({required this.imageAsset, required this.height});
  final String? imageAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null) return SizedBox(height: height * 0.3);
    return SizedBox(
      height: height,
      child: Image.asset(imageAsset!, fit: BoxFit.contain),
    );
  }
}

class _WordDraggable extends StatelessWidget {
  const _WordDraggable({
    required this.word,
    required this.answered,
    required this.lastCorrect,
  });

  final Word word;
  final bool answered;
  final bool? lastCorrect;

  @override
  Widget build(BuildContext context) {
    // Po odpowiedzi wpisujemy poprawną literę w lukę — finał edukacyjny.
    final displayText = answered
        ? word.mask.replaceAll('_', word.correct)
        : word.mask;
    final highlight = answered
        ? ((lastCorrect ?? false) ? KidsColors.success : KidsColors.warn)
        : null;

    final chip = _WordVisual(text: displayText, highlight: highlight);
    if (answered) return chip;

    return Draggable<String>(
      data: word.correct,
      feedback: Material(
        color: Colors.transparent,
        child: _WordVisual(text: displayText, scale: 1.1),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: chip),
      child: chip,
    );
  }
}

class _WordVisual extends StatelessWidget {
  const _WordVisual({
    required this.text,
    this.highlight,
    this.scale = 1.0,
  });

  final String text;
  final Color? highlight;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight ?? KidsColors.seed.withValues(alpha: 0.35),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: highlight ?? KidsColors.ink,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({
    required this.letter,
    required this.answered,
    required this.showCorrectGlow,
    required this.onAccept,
  });

  final String letter;
  final bool answered;
  final bool showCorrectGlow;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !answered,
      onAcceptWithDetails: (_) => onAccept(),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final glowColor = showCorrectGlow
            ? KidsColors.success
            : hovering
                ? KidsColors.seed
                : Colors.transparent;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          // 112×112 (-20% z 140). Ten sam powód co LetterButton: zgłoszenie
          // koleżanki z Samsunga że worki wystają poza kafelek karty.
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (glowColor != Colors.transparent)
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Prawdziwy jutowy worek — akwarela, transparent PNG.
              Image.asset(
                'assets/images/ui/sack.png',
                fit: BoxFit.contain,
              ),
              // Litera jakby "wymalowana" na worku. FittedBox obsłuży
              // multi-char jak "si"/"ci".
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: KidsColors.ink,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedbackHint extends StatelessWidget {
  const _FeedbackHint({required this.word, required this.correct});

  final Word word;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final text = correct
        ? word.exampleHint
        : '${word.rule.hint}\n${word.exampleHint}';
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
