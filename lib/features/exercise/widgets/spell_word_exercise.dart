import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/exercise/session_state.dart';

/// Wariant ćwiczenia: **ułóż słowo z liter**.
///
/// Pedagogicznie inny od chooseLetter/dragLetter/categorySort — te są
/// wariantami "wybierz 1 z 2 liter". SpellWord ćwiczy **produkcję**
/// całego wyrazu, angażując pamięć wzrokową pełnego wzorca.
///
/// Mechanika:
/// 1. Obrazek + puste sloty na każdą literę.
/// 2. Rozsypane litery słowa + 2 dystraktory (zamiast tego co należałoby).
/// 3. Tap litery = wstawienie do następnego wolnego slotu.
/// 4. Jeśli litera pasuje w bieżącej pozycji → advance.
///    Jeśli NIE → shake + pozostajemy w tym samym slocie (errorless learning).
/// 5. Po wstawieniu wszystkich liter → `answer(correct)`.
///
/// Ten widget jest używany tylko gdy słowo ma `imageAsset` — bez obrazka
/// dziecko nie wie co ma ułożyć. QuestionSelector/provider filtruje.
class SpellWordExercise extends ConsumerStatefulWidget {
  const SpellWordExercise({required this.state, super.key});

  final SessionActive state;

  @override
  ConsumerState<SpellWordExercise> createState() => _SpellWordExerciseState();
}

class _SpellWordExerciseState extends ConsumerState<SpellWordExercise> {
  late final List<_Tile> _tiles;
  late final List<String> _filledSlots; // [i] == litera lub ''
  int _mistakeOnTile = -1; // id tile do shake'owania

  String get _text => widget.state.currentWord.text;
  int get _currentSlot => _filledSlots.indexOf('');

  @override
  void initState() {
    super.initState();
    _filledSlots = List<String>.filled(_text.length, '');
    _tiles = _buildTiles(widget.state.currentWord);
  }

  /// Buduje listę "kafli" z liter słowa + 1-2 dystraktorów. Kafle mają
  /// unikalne id, żeby widget mógł je ukrywać po użyciu.
  List<_Tile> _buildTiles(Word word) {
    final text = word.text;
    final letters = <String>[
      for (var i = 0; i < text.length; i++) text[i],
    ];
    // Dystraktor: litera która nie występuje w słowie, preferując tę
    // z pary ortograficznej (jeśli correct to "ó" → dystraktor "u" itd.).
    //
    // Mechanika spell-word jest slot-per-char, więc wielo-znakowy
    // distractor jak "si"/"ci" tniemy do pierwszej litery — pedagogika
    // nadal ma sens (dziecko widzi "s" jako czerwoną śledź dla "ś").
    final distractors = <String>[];
    final primaryDistractor =
        word.distractor.isEmpty ? '' : word.distractor[0];
    final candidates = [
      primaryDistractor,
      ...word.correct.split(''),
      'a', 'e', 'i', 'o',
    ];
    for (final c in candidates) {
      if (distractors.length >= 2) break;
      if (!text.contains(c) && !distractors.contains(c)) {
        distractors.add(c);
      }
    }
    final allLetters = [...letters, ...distractors];
    final rng = Random(word.id.hashCode);
    allLetters.shuffle(rng);
    return [
      for (var i = 0; i < allLetters.length; i++)
        _Tile(id: i, letter: allLetters[i]),
    ];
  }

  void _onTileTap(_Tile tile) {
    if (widget.state.isAnswered) return;
    final slot = _currentSlot;
    if (slot == -1) return;

    final expected = _text[slot];
    if (tile.letter == expected) {
      setState(() {
        _filledSlots[slot] = tile.letter;
        tile.used = true;
        _mistakeOnTile = -1;
      });
      if (slot + 1 == _text.length) {
        // Słowo ułożone poprawnie — rejestruj correct w sesji po mikrotasku,
        // żeby nie modyfikować stanu w środku setState.
        unawaited(
          Future.microtask(() async {
            if (!mounted) return;
            await ref.read(exerciseSessionProvider.notifier).answer(
                  widget.state.currentWord.correct,
                );
          }),
        );
      }
    } else {
      setState(() => _mistakeOnTile = tile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.state.currentWord;
    final imageHeight = MediaQuery.of(context).size.height * 0.22;

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
          'Ułóż słowo z liter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KidsColors.ink.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        if (word.imageAsset != null)
          SizedBox(
            height: imageHeight,
            child: Image.asset(word.imageAsset!, fit: BoxFit.contain),
          ),
        const SizedBox(height: 14),
        _SlotsRow(slots: _filledSlots, highlightLast: widget.state.isAnswered),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tile in _tiles)
              _LetterTile(
                tile: tile,
                shake: _mistakeOnTile == tile.id,
                onTap: () => _onTileTap(tile),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tile {
  _Tile({required this.id, required this.letter});
  final int id;
  final String letter;
  bool used = false;
}

class _SlotsRow extends StatelessWidget {
  const _SlotsRow({required this.slots, required this.highlightLast});

  final List<String> slots;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    // FittedBox: długie słowa (np. "przyjaciółka" = 13 liter × 44px =
    // ~580px) nie zmieszczą się w ekranie. scaleDown skaluje cały wiersz
    // zachowując proporcje.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          _Slot(
            letter: slots[i],
            highlight: highlightLast && slots[i].isNotEmpty,
          ),
          if (i < slots.length - 1) const SizedBox(width: 4),
        ],
      ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.letter, required this.highlight});

  final String letter;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final filled = letter.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: filled ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled
              ? (highlight
                  ? KidsColors.success
                  : KidsColors.ink.withValues(alpha: 0.4))
              : KidsColors.ink.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: highlight ? KidsColors.success : KidsColors.ink,
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.tile,
    required this.shake,
    required this.onTap,
  });

  final _Tile tile;
  final bool shake;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visible = !tile.used;
    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(
          shake ? -4 : 0,
          0,
          0,
        ),
        child: Material(
          color: KidsColors.seed,
          borderRadius: BorderRadius.circular(14),
          elevation: 3,
          shadowColor: KidsColors.seed.withValues(alpha: 0.4),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: visible ? onTap : null,
            child: SizedBox(
              width: 52,
              height: 56,
              child: Center(
                child: Text(
                  tile.letter,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
