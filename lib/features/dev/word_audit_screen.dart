import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/core/content/word_repository.dart';
import 'package:teach_me/features/exercise/widgets/word_mask_view.dart';

/// Debug-only screen — renderuje wszystkie słowa z bazy w prawdziwych
/// widgetach maski (WordMaskView + drag-mask preview), w trzech
/// szerokościach kontenera (320 / 360 / 411 dp), żeby zwizualizować
/// czy FittedBox proporcjonalnie skaluje długie słowa.
///
/// Dostęp: 5 tapów na nagłówku "JerzyUczy" w `O aplikacji`.
/// Nie pokazany w żadnym menu user-facing.
class WordAuditScreen extends ConsumerWidget {
  const WordAuditScreen({super.key});

  // Szerokości symulowane. Górna granica musi się mieścić w samym
  // audit-screenie nawet na 360dp telefonie — dlatego max 320dp dla
  // symulowanej karty wewnętrznej. To i tak pokrywa najgorszy case
  // (320 = stary Galaxy A3, niżej praktycznie nikt).
  static const _previewWidths = <double>[260, 290, 320];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(_allWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audyt słów'),
        backgroundColor: KidsColors.surface,
      ),
      backgroundColor: KidsColors.surface,
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (groups) => _AuditList(groups: groups),
      ),
    );
  }
}

final _allWordsProvider = FutureProvider<List<_TopicGroup>>((ref) async {
  final repo = ref.read(wordRepositoryProvider);
  final all = await repo.loadAll();
  // Grupowanie po topic, posortowane po długości tekstu malejąco
  // (najtrudniejsze przypadki na górze każdej grupy).
  final byTopic = <OrthographyTopic, List<Word>>{};
  for (final w in all) {
    if (w.topic == OrthographyTopic.findError) continue;
    byTopic.putIfAbsent(w.topic, () => []).add(w);
  }
  for (final list in byTopic.values) {
    list.sort((a, b) => b.text.length.compareTo(a.text.length));
  }
  return byTopic.entries
      .map((e) => _TopicGroup(topic: e.key, words: e.value))
      .toList();
});

class _TopicGroup {
  const _TopicGroup({required this.topic, required this.words});
  final OrthographyTopic topic;
  final List<Word> words;
}

class _AuditList extends StatelessWidget {
  const _AuditList({required this.groups});
  final List<_TopicGroup> groups;

  @override
  Widget build(BuildContext context) {
    final totalWords = groups.fold<int>(0, (s, g) => s + g.words.length);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Audyt FittedBox-a w WordMaskView. Każde słowo renderowane '
            'w 3 zwężających się szerokościach kontenera (260 / 290 / 320 '
            'dp), żeby zobaczyć czy ładnie się skaluje.\n\n'
            'Słowa posortowane od najdłuższego.\n\n'
            'Łącznie: $totalWords słów.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        for (final g in groups) ...[
          _GroupHeader(group: g),
          for (final w in g.words) _WordRow(word: w),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});
  final _TopicGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: group.topic.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              group.topic.shortLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${group.topic.label} — ${group.words.length} słów',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: KidsColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                word.text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${word.text.length} liter, mask "${word.mask}")',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final w in WordAuditScreen._previewWidths) ...[
            _Preview(word: word, width: w),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// Renderuje WordMaskView w kontenerze o ustalonej szerokości — symuluje
/// rzeczywiste warunki layoutu na telefonie o danej szerokości viewportu.
///
/// Kalkulacja: viewport `width` minus 16+16 outer padding (Padding w
/// ExerciseCard) minus 20+20 card padding = `innerWidth`.
class _Preview extends StatelessWidget {
  const _Preview({required this.word, required this.width});
  final Word word;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cardWidth = width.clamp(0.0, 460.0) - 32;
    final innerWidth = cardWidth - 40;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '${width.toInt()}dp',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          // ClipRect: jeśli mimo FittedBox coś by wyleciało, ucinamy
          // wizualnie do bounds (zamiast pasy żółto-czarne).
          ClipRect(
            child: Container(
              width: innerWidth,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: WordMaskView(
                mask: word.mask,
                filledLetter: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
