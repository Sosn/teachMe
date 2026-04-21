import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/exercise/session_state.dart';

/// Wariant ćwiczenia: dziecko **przeciąga** literę z paska do luki w słowie.
///
/// Motoryka duża > mała — dla 7-9 latków drag jest bardziej intuicyjny
/// niż precyzyjny tap, a pedagogicznie angażuje inne obszary uwagi
/// (planowanie ruchu, koordynacja wzrokowo-ruchowa).
class DragLetterExercise extends ConsumerWidget {
  const DragLetterExercise({required this.state, super.key});

  final SessionActive state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = state.currentWord;
    final answered = state.isAnswered;
    final lastCorrect = state.lastAnswerCorrect;
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
          // „literę" myli dla dwuznaków (rz, sz, ch) i sekwencji (om, on).
          'Przeciągnij to, co pasuje w luce',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        _WordImage(imageAsset: word.imageAsset, height: imageHeight),
        const SizedBox(height: 16),
        _DragMaskView(
          mask: word.mask,
          answered: answered,
          filledLetter: answered ? word.correct : null,
          lastCorrect: lastCorrect,
          onAccept: (letter) =>
              ref.read(exerciseSessionProvider.notifier).answer(letter),
        ),
        const SizedBox(height: 24),
        _DraggableLettersRow(
          word: word,
          answered: answered,
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
    if (imageAsset == null) {
      return SizedBox(height: height * 0.6);
    }
    return SizedBox(
      height: height,
      child: Image.asset(imageAsset!, fit: BoxFit.contain),
    );
  }
}

/// Maska słowa z DragTarget w miejscu luki.
class _DragMaskView extends StatelessWidget {
  const _DragMaskView({
    required this.mask,
    required this.answered,
    required this.filledLetter,
    required this.lastCorrect,
    required this.onAccept,
  });

  final String mask;
  final bool answered;
  final String? filledLetter;
  final bool? lastCorrect;
  final void Function(String letter) onAccept;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < mask.length; i++) {
      final ch = mask[i];
      if (ch == '_') {
        children.add(
          _DropSlot(
            answered: answered,
            filledLetter: filledLetter,
            lastCorrect: lastCorrect,
            onAccept: onAccept,
          ),
        );
      } else {
        children.add(
          Text(
            ch,
            style: const TextStyle(
              fontSize: 56,
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

class _DropSlot extends StatelessWidget {
  const _DropSlot({
    required this.answered,
    required this.filledLetter,
    required this.lastCorrect,
    required this.onAccept,
  });

  final bool answered;
  final String? filledLetter;
  final bool? lastCorrect;
  final void Function(String letter) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !answered,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final borderColor = hovering
            ? KidsColors.seed
            : KidsColors.ink.withValues(alpha: 0.35);
        final bgColor = hovering
            ? KidsColors.seed.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.4);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: hovering ? 3 : 2,
              style: answered ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          alignment: Alignment.center,
          child: filledLetter == null
              ? Icon(
                  Icons.arrow_downward_rounded,
                  color: KidsColors.ink.withValues(alpha: 0.4),
                  size: 28,
                )
              : Text(
                  filledLetter!,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: (lastCorrect ?? false)
                        ? KidsColors.success
                        : KidsColors.warn,
                    height: 1,
                  ),
                ),
        );
      },
    );
  }
}

/// Dwa Draggable z literami. Po odpowiedzi zastygają — żeby dziecko nie
/// mogło przeciągnąć drugiej, gdy już widać wynik.
class _DraggableLettersRow extends StatelessWidget {
  const _DraggableLettersRow({required this.word, required this.answered});

  final Word word;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final correctFirst = word.id.hashCode.isEven;
    final letters = correctFirst
        ? [word.correct, word.distractor]
        : [word.distractor, word.correct];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LetterChip(letter: letters[0], enabled: !answered),
        const SizedBox(width: 28),
        _LetterChip(letter: letters[1], enabled: !answered),
      ],
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({required this.letter, required this.enabled});

  final String letter;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chip = _LetterVisual(letter: letter, size: 96, dragging: false);
    if (!enabled) {
      return Opacity(opacity: 0.5, child: chip);
    }
    return Draggable<String>(
      data: letter,
      feedback: Material(
        color: Colors.transparent,
        child: _LetterVisual(letter: letter, size: 112, dragging: true),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: chip),
      child: chip,
    );
  }
}

class _LetterVisual extends StatelessWidget {
  const _LetterVisual({
    required this.letter,
    required this.size,
    required this.dragging,
  });

  final String letter;
  final double size;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KidsColors.seed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: KidsColors.seed.withValues(alpha: dragging ? 0.5 : 0.35),
            blurRadius: dragging ? 24 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      // FittedBox skaluje "si"/"ci"/"ni"/"zi" żeby zmieściły się w chipie.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
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
