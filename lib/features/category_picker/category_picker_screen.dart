import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teach_me/app/router.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/features/exercise/exercise_session_provider.dart';
import 'package:teach_me/features/mascot/mascot_mood.dart';
import 'package:teach_me/features/mascot/mascot_view.dart';
import 'package:teach_me/shared/widgets/scene_background.dart';

/// Ekran wyboru kategorii ortograficznej. Po kliknięciu przedmiotu
/// "Ortografia" dziecko dostaje 3 wyraziste kubełki: ó/u, rz/ż, ch/h.
/// Sesja trenuje TYLKO wybraną kategorię — bez mieszania, żeby reguła
/// miała szansę zakodować się pamięciowo przez powtórzenia.
class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KidsColors.ink),
          tooltip: 'Wybór przedmiotu',
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ortografia',
          style: TextStyle(
            color: KidsColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SceneBackdrop(
        scene: SceneBackground.menu,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      const MascotView(mood: MascotMood.happy, size: 225),
                      const SizedBox(height: 12),
                      const _Headline(),
                      const SizedBox(height: 24),
                      for (final topic in OrthographyTopic.values) ...[
                        _TopicCard(
                          topic: topic,
                          onTap: () {
                            // Ustawiamy aktywny topic PRZED nawigacją, żeby
                            // ExerciseSessionProvider od razu zbudował sesję
                            // dla właściwej kategorii.
                            ref.read(currentTopicProvider.notifier).state =
                                topic;
                            unawaited(
                              context.push(
                                Routes.orthographyTopic(topic.id),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        'Wybierz, co trenujemy',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: KidsColors.ink,
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final OrthographyTopic topic;
  final VoidCallback onTap;

  String get _subtitle => switch (topic) {
        OrthographyTopic.ouU => 'Wymiana, końcówki, wyjątki',
        OrthographyTopic.rzZ => 'Spółgłoska, wymiana r, wyjątki',
        OrthographyTopic.chH => 'ch podstawowe, h obce, wymiany',
        OrthographyTopic.aoEn => 'Nosówki i ich wymiana',
        OrthographyTopic.scNz => 'Miękkie spółgłoski',
        OrthographyTopic.findError => 'Znajdź błąd w zdaniu',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: topic.accent,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: topic.accent.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  topic.shortLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ortografia ${topic.label}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
