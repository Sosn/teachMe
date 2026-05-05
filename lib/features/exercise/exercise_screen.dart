import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teach_me/app/router.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/stats/stats_store.dart';
import 'package:teach_me/features/about/parental_gate.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/exercise/exercise_type.dart';
import 'package:teach_me/features/exercise/session_state.dart';
import 'package:teach_me/features/exercise/widgets/category_sort_exercise.dart';
import 'package:teach_me/features/exercise/widgets/choose_letter_exercise.dart';
import 'package:teach_me/features/exercise/widgets/drag_letter_exercise.dart';
import 'package:teach_me/features/exercise/widgets/find_error_exercise.dart';
import 'package:teach_me/features/exercise/widgets/spell_word_exercise.dart';
import 'package:teach_me/features/mascot/mascot_mood.dart';
import 'package:teach_me/features/mascot/mascot_view.dart';
import 'package:teach_me/features/stats/stats_screen.dart';
import 'package:teach_me/shared/widgets/scene_background.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({required this.topic, super.key});

  final OrthographyTopic topic;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  @override
  void initState() {
    super.initState();
    // Ustawiamy topic w provider po pierwszym frame — session provider
    // zbuduje się dla właściwej kategorii.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentTopicProvider.notifier).state = widget.topic;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(exerciseSessionProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: KidsColors.ink),
          tooltip: 'Wyjdź z ćwiczenia',
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ortografia ${widget.topic.label}',
          style: const TextStyle(
            color: KidsColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SceneBackdrop(
        scene: SceneBackground.exercise,
        child: SafeArea(
          child: switch (session) {
            SessionLoading() =>
              const Center(child: CircularProgressIndicator()),
            SessionActive() => _ActiveSession(state: session),
            SessionFinished() => _SessionSummary(state: session),
          },
        ),
      ),
    );
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({required this.state});

  final SessionActive state;

  @override
  Widget build(BuildContext context) {
    final mood = switch (state.lastAnswerCorrect) {
      true => MascotMood.happy,
      false => MascotMood.sad,
      null => MascotMood.neutral,
    };

    final exerciseWidget = switch (state.currentType) {
      ExerciseType.chooseLetter => ChooseLetterExercise(state: state),
      ExerciseType.dragLetter => DragLetterExercise(state: state),
      ExerciseType.categorySort => CategorySortExercise(state: state),
      ExerciseType.spellWord => SpellWordExercise(
          // Key związany z id słowa — stan kafli resetuje się przy zmianie.
          key: ValueKey('spell_${state.currentWord.id}'),
          state: state,
        ),
      ExerciseType.findError => FindErrorExercise(
          // Key: reset _tappedIndex przy zmianie pytania.
          key: ValueKey('finderr_${state.currentWord.id}'),
          state: state,
        ),
    };

    return Stack(
      children: [
        // Outer LayoutBuilder daje viewport karty; SingleChildScrollView
        // wewnątrz scrolluje gdy zawartość większa od ekranu (duże
        // systemowe czcionki, niskie urządzenia, splittowane okno).
        // Padding bottom: 50 — strefa „nic poza tłem" pod system gesture
        // bar (Samsung One UI / MIUI / iPhone home indicator). ConstrainedBox
        // z minHeight = viewport pozwala Center centrować gdy treść mieści
        // się na ekranie, a scrollować gdy nie.
        LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewport.maxHeight - 66, // top 16 + bottom 50
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Mascot proporcjonalnie do szerokości karty.
                        // Cap 160 dla tabletów (karta ma maxWidth 460).
                        final mascotSize =
                            (constraints.maxWidth * 0.34).clamp(110.0, 160.0);
                        // 70% maskotki nad krawędzią karty, 30% wchodzi.
                        final cardTopOffset = mascotSize * 0.7;
                        return Stack(
                          clipBehavior: Clip.none, // mascot wystaje
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: cardTopOffset),
                              child: _ExerciseCard(
                                // Padding-top karty żeby polecenie nie
                                // wchodziło pod łapki jeża (30% maskotki
                                // w karcie = mascotSize * 0.3 + odstęp).
                                topPadding: mascotSize * 0.3 + 8,
                                child: exerciseWidget,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 12,
                              child: MascotView(mood: mood, size: mascotSize),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (state.isAnswered)
          const Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: _NextButton(),
            ),
          ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.child, this.topPadding = 24});

  final Widget child;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NextButton extends ConsumerWidget {
  const _NextButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: KidsColors.seed,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(exerciseSessionProvider.notifier).next(),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _SessionSummary extends ConsumerStatefulWidget {
  const _SessionSummary({required this.state});

  final SessionFinished state;

  @override
  ConsumerState<_SessionSummary> createState() => _SessionSummaryState();
}

class _SessionSummaryState extends ConsumerState<_SessionSummary> {
  static const _supportModalKey = 'app.supportModalShown';
  static const _supportMilestone = 100;

  SessionFinished get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeShowSupportModal());
    });
  }

  /// Pokazuje modal wsparcia po przekroczeniu kamienia milowego 100
  /// poprawnych odpowiedzi. Pokazany TYLKO RAZ w życiu aplikacji
  /// (flaga w shared_preferences). Nie blokuje przejścia dalej.
  Future<void> _maybeShowSupportModal() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_supportModalKey) == true) return;

    final snapshot = await ref.read(statsSnapshotProvider.future);
    final totalCorrect = snapshot.lifetime.values
        .fold<int>(0, (sum, s) => sum + s.correct);
    if (totalCorrect < _supportMilestone) return;
    if (!mounted) return;

    // Zapisujemy flagę natychmiast, żeby nawet jeśli user zamknie dialog
    // bez decyzji — nie pokażemy go znowu.
    await prefs.setBool(_supportModalKey, true);
    if (!mounted) return;

    await _showSupportModal(totalCorrect);
  }

  Future<void> _showSupportModal(int totalCorrect) async {
    final goToAbout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Gratulacje!'),
        content: Text(
          'Twoje dziecko rozwiązało już $totalCorrect poprawnych pytań!\n\n'
          'Zrobiłem JerzyUczy sam, wieczorami, dla swoich dzieci i innych '
          'polskich uczniów. Jeśli aplikacja Ci pomaga — możesz wesprzeć '
          'jej rozwój dowolnym BLIKIEM. To nie jest wymagane, ale '
          'bardzo motywuje do dalszej pracy. ❤️',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Może później'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('Zobacz jak wesprzeć'),
          ),
        ],
      ),
    );
    if (goToAbout != true || !mounted) return;

    // Przed otwarciem AboutScreen (z BLIKiem / emailem) — parental gate.
    final passed = await ParentalGate.show(context);
    if (!passed || !mounted) return;
    await context.push(Routes.about);
  }

  /// Dialog potwierdzenia + reset progresu + restart sesji.
  /// Wywoływane gdy pula jest wyczerpana (total == 0) — typowa
  /// sytuacja po odpowiedzi na wszystkie słowa kategorii poprawnie.
  Future<void> _confirmResetAndRestart(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final topic = state.topic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Zresetować postęp kategorii ${topic.label}?'),
        content: const Text(
          'Wyczyścimy postęp nauki (Leitner) oraz statystyki „od resetu" '
          'dla tej kategorii. Wszystkie słowa znów pojawią się jak nowe. '
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
    // exerciseSessionProvider został invalidated — świeża sesja
    // załaduje się z nowym zestawem pytań. Restart niepotrzebny.
  }

  @override
  Widget build(BuildContext context) {
    final total = state.total;
    final correct = state.totalCorrect;
    final ratio = total == 0 ? 0.0 : correct / total;
    final mood = total == 0 || ratio < 0.3
        ? MascotMood.neutral
        : ratio >= 0.7
            ? MascotMood.happy
            : MascotMood.neutral;
    final headline = total == 0
        ? 'Świetnie! Wszystkie słowa tej kategorii są w powtórce.\n'
            'Wróć jutro albo zresetuj postęp, żeby ćwiczyć od nowa.'
        : 'Koniec sesji! Trafiłeś $correct z $total.';

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            SceneBackground.summary.asset,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              MascotView(mood: mood, size: 300),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: KidsColors.ink,
                    height: 1.25,
                  ),
                ),
              ),
              const Spacer(),
              if (total > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(exerciseSessionProvider.notifier)
                        .restart(),
                    child: const Text('Jeszcze raz'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmResetAndRestart(context, ref),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Zresetuj postęp tej kategorii'),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.55),
                  foregroundColor: KidsColors.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Powrót do wyboru kategorii',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
