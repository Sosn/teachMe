import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teach_me/app/router.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/features/about/parental_gate.dart';
import 'package:teach_me/shared/widgets/scene_background.dart';

/// Root ekran aplikacji — wybór przedmiotu do nauki. W MVP tylko ortografia
/// jest aktywna; matma i czytanie pokazywane jako "wkrótce", żeby dziecko
/// (i rodzic) widział mapę drogową.
class SubjectPickerScreen extends StatelessWidget {
  const SubjectPickerScreen({super.key});

  /// Wejście na ekran "O aplikacji" wymaga parental gate — Google Play
  /// "Designed for Families" wymaga tego dla każdej akcji wychodzącej
  /// (BLIK, email, linki zewnętrzne).
  Future<void> _openAbout(BuildContext context) async {
    final passed = await ParentalGate.show(context);
    if (!passed || !context.mounted) return;
    await context.push(Routes.about);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const SizedBox.shrink(),
        leading: IconButton(
          tooltip: 'O aplikacji',
          iconSize: 26,
          icon: const Icon(
            Icons.info_outline_rounded,
            color: KidsColors.ink,
          ),
          onPressed: () => _openAbout(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Statystyki',
            iconSize: 28,
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: KidsColors.ink,
            ),
            onPressed: () => context.push(Routes.stats),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SceneBackdrop(
        scene: SceneBackground.menu,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Headline(),
                      const SizedBox(height: 28),
                      _SubjectsGrid(
                        onOrthography: () =>
                            context.push(Routes.orthography),
                      ),
                      const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        'Czego chcesz się dziś uczyć?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: KidsColors.ink,
          height: 1.2,
        ),
      ),
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({required this.onOrthography});

  final VoidCallback onOrthography;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1,
      children: [
        _SubjectCard(
          icon: Icons.spellcheck,
          label: 'Ortografia',
          subtitle: 'ó, u, rz, ż',
          active: true,
          onTap: onOrthography,
        ),
        const _SubjectCard(
          icon: Icons.calculate,
          label: 'Matematyka',
          subtitle: 'Wkrótce',
          active: false,
          onTap: null,
        ),
        const _SubjectCard(
          icon: Icons.menu_book,
          label: 'Czytanie',
          subtitle: 'Wkrótce',
          active: false,
          onTap: null,
        ),
        const _SubjectCard(
          icon: Icons.palette,
          label: 'Plastyka',
          subtitle: 'Wkrótce',
          active: false,
          onTap: null,
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? KidsColors.seed
        : Colors.white.withValues(alpha: 0.75);
    final fg = active ? Colors.white : KidsColors.ink.withValues(alpha: 0.45);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      elevation: active ? 4 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: fg),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fg.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
