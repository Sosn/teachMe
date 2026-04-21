import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teach_me/app/router.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word_repository.dart';
import 'package:teach_me/core/stats/category_stats.dart';
import 'package:teach_me/core/stats/stats_snapshot.dart';
import 'package:teach_me/core/stats/stats_store.dart';
import 'package:teach_me/core/storage/progress_store.dart';
import 'package:teach_me/features/about/parental_gate.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/shared/widgets/scene_background.dart';

/// Widok statystyk. Dla każdej z 4 kategorii pokazujemy dwa wymiary:
/// `lifetime` (od początku, nieresetowalne) i `sinceReset` (resetowalne
/// per kategoria przyciskiem). Wchodzimy z SubjectPicker (ikona bar_chart).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statsSnapshotProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KidsColors.ink),
          tooltip: 'Wróć',
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Statystyki',
          style: TextStyle(
            color: KidsColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SceneBackdrop(
        scene: SceneBackground.menu,
        child: SafeArea(
          child: async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Ups: $e'),
              ),
            ),
            data: (snapshot) => _StatsList(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class _StatsList extends StatelessWidget {
  const _StatsList({required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final topic in OrthographyTopic.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CategoryCard(topic: topic, snapshot: snapshot),
          ),
        const SizedBox(height: 4),
        const _SupportBanner(),
      ],
    );
  }
}

/// Banner wsparcia na dole StatsScreen (widok dla rodzica). Tap →
/// parental gate → AboutScreen. Solid tło żeby był wyraźnie widoczny.
class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  Future<void> _openAbout(BuildContext context) async {
    final passed = await ParentalGate.show(context);
    if (!passed || !context.mounted) return;
    await context.push(Routes.about);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KidsColors.warn,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: KidsColors.warn.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openAbout(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Widok dla rodziców',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Wsparcie twórcy, kontakt, opinia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.topic, required this.snapshot});

  final OrthographyTopic topic;
  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifetime = snapshot.lifetimeFor(topic);
    final sinceReset = snapshot.sinceResetFor(topic);
    final resetAt = snapshot.lastResetFor(topic);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: topic.accent.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: topic.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  topic.shortLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topic.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: KidsColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatsColumn(
                  title: 'Od początku',
                  subtitle: null,
                  stats: lifetime,
                  accent: topic.accent,
                ),
              ),
              Container(
                width: 1,
                height: 110,
                color: KidsColors.ink.withValues(alpha: 0.12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _StatsColumn(
                  title: 'Od resetu',
                  subtitle: resetAt != null
                      ? 'Zresetowano ${_formatDate(resetAt)}'
                      : 'Nigdy nie zresetowano',
                  stats: sinceReset,
                  accent: topic.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
              label: const Text('Zresetuj kategorię'),
              style: TextButton.styleFrom(
                foregroundColor: topic.accent,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Zresetować kategorię ${topic.label}?'),
        content: const Text(
          'Wyczyścimy statystyki „od resetu" oraz postęp nauki (Leitner) '
          'dla tej kategorii — wszystkie słowa znów pojawią się jak nowe. '
          'Statystyki „od początku" zostają nietknięte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: topic.accent),
            child: const Text('Zresetuj'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await resetCategoryProgress(ref, topic);
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year}';
  }
}

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.accent,
  });

  final String title;
  final String? subtitle;
  final CategoryStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: KidsColors.ink.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _Row(label: 'Sesje', value: '${stats.sessions}'),
        _Row(label: 'Pytania', value: '${stats.questions}'),
        _Row(label: 'Poprawne', value: '${stats.correct}'),
        _Row(
          label: 'Trafność',
          value: stats.questions == 0
              ? '—'
              : '${(stats.accuracy * 100).round()}%',
        ),
      ],
    );
  }
}

/// Resetuje jedną kategorię: czyści „od resetu" w stats oraz usuwa
/// progres Leitnera dla wszystkich słów tej kategorii. Dzięki temu
/// dziecko/rodzic nie musi czekać na interwał Leitnera — wszystkie
/// słowa znów są "nowe" i QuestionSelector je wylosuje.
///
/// Używane z dwóch miejsc: StatsScreen (dialog "Zresetuj kategorię")
/// i ExerciseScreen (przycisk w podsumowaniu gdy pula jest pusta).
Future<void> resetCategoryProgress(
  WidgetRef ref,
  OrthographyTopic topic,
) async {
  // 1) Stats — "od resetu" wyzerowane, "od początku" zostaje.
  final statsStore = await ref.read(statsStoreProvider.future);
  await statsStore.resetCategory(topic, at: DateTime.now());

  // 2) Progress Leitnera — usuwamy wpisy dla wszystkich słów z tej
  //    kategorii. Słowa wracają do stanu "nowe" przy następnym
  //    załadowaniu sesji.
  final repo = ref.read(wordRepositoryProvider);
  final words = await repo.loadByTopic(topic);
  final progressStore = await ref.read(progressStoreProvider.future);
  await progressStore.removeMany(words.map((w) => w.id));

  // 3) Świeża sesja ćwiczeń z nowym progressem.
  ref
    ..invalidate(statsSnapshotProvider)
    ..invalidate(exerciseSessionProvider);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: KidsColors.ink.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: KidsColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
