import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:teach_me/app/router.dart';
import 'package:teach_me/app/theme.dart';
import 'package:teach_me/features/mascot/mascot_mood.dart';
import 'package:teach_me/features/mascot/mascot_view.dart';
import 'package:teach_me/shared/widgets/scene_background.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ekran "O aplikacji" — dostępny przez ikonę "info" w SubjectPickerScreen.
///
/// **Ważne:** wejście na ten ekran wymaga przejścia przez `ParentalGate`
/// (Google Play "Designed for Families" wymaga tego dla każdej akcji
/// wychodzącej z aplikacji: BLIK, email, linki zewnętrzne).
///
/// Zawiera:
/// - Krótki opis aplikacji + wersja
/// - Wsparcie twórcy (BLIK z tap-to-copy)
/// - Formularz feedbacku (textarea → mailto:)
/// - Dane kontaktowe + credits
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const String _blikNumber = '730795313';
  static const String _blikDisplay = '730 795 313';
  static const String _contactEmail = 'soswa.k@gmail.com';
  static const String _appVersion = '0.5 (beta)';

  final TextEditingController _feedbackController = TextEditingController();

  /// Licznik tapów na nagłówku "JerzyUczy" — 5 tapów otwiera debug
  /// screen z audytem wszystkich słów. Reset po 2s bez tapów.
  int _titleTapCount = 0;
  DateTime _lastTitleTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _onTitleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTitleTap).inSeconds > 2) {
      _titleTapCount = 1;
    } else {
      _titleTapCount += 1;
    }
    _lastTitleTap = now;
    if (_titleTapCount >= 5) {
      _titleTapCount = 0;
      context.push(Routes.devWordAudit);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _copyBlik() async {
    await Clipboard.setData(const ClipboardData(text: _blikNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skopiowano numer do BLIKa. Otwórz swoją bankową aplikację.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final body = _feedbackController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Napisz coś zanim wyślesz opinię.')),
      );
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      query: _encodeQuery({
        'subject': 'JerzyUczy — opinia (v$_appVersion)',
        'body': body,
      }),
    );
    await _launch(uri);
  }

  Future<void> _openPlainEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      query: _encodeQuery({
        'subject': 'JerzyUczy (v$_appVersion) — kontakt',
      }),
    );
    await _launch(uri);
  }

  /// Ręczne encodowanie `?k=v&k2=v2`, bo Uri.queryParameters encoduje
  /// spacje jako `+` co niektóre klienty pocztowe odczytują dosłownie.
  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  Future<void> _launch(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie mogę otworzyć aplikacji pocztowej.'),
          ),
        );
      }
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coś poszło nie tak. Spróbuj ponownie.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'O aplikacji',
          style: TextStyle(
            color: KidsColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SceneBackdrop(
        scene: SceneBackground.menu,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Kafelek z awatarem + nazwą + wersją — żeby tekst był
                // czytelny na ciemniejszym tle sceny.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const MascotView(mood: MascotMood.happy, size: 130),
                      const SizedBox(height: 6),
                      // 5 tapów na ten tytuł → debug screen audytu słów.
                      // Behavior.opaque żeby cały obszar Texta przyjmował
                      // tapy (a nie tylko piksele liter).
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onTitleTap,
                        child: const Text(
                          'JerzyUczy',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: KidsColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        'Ortografia dla klas 3–4 • v$_appVersion',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KidsColors.ink.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _Card(
                  icon: Icons.school_outlined,
                  title: 'O aplikacji',
                  child: Text(
                    'JerzyUczy pomaga dzieciom z klas 3–4 opanować polską '
                    'ortografię przez krótkie, kolorowe ćwiczenia. Aplikacja '
                    'działa całkowicie offline, nie zbiera żadnych danych '
                    'osobowych i nie zawiera reklam.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  icon: Icons.chat_bubble_outline,
                  title: 'Podziel się opinią',
                  accent: KidsColors.seed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Chcę wiedzieć WSZYSTKO — co Ci się podobało, co nie, '
                        'jakie błędy znalazłeś, czego brakuje.\n\n'
                        'Twoja opinia ma realny wpływ na to, co powstanie '
                        'dalej: jakie sekcje, jakie nowe typy ćwiczeń, '
                        'co poprawiamy w pierwszej kolejności.',
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 8,
                        minLines: 6,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText:
                              'Co się podobało?\nCo nie?\nJakie błędy znalazłeś?\nCzego brakuje?',
                          hintStyle: TextStyle(
                            color: KidsColors.ink.withValues(alpha: 0.4),
                            height: 1.5,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: KidsColors.ink.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: KidsColors.seed,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sendFeedback,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Wyślij opinię e-mailem'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  icon: Icons.favorite_outline,
                  title: 'Wesprzyj twórcę (BLIK)',
                  accent: KidsColors.warn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Jeśli aplikacja Ci pomaga, możesz wesprzeć jej '
                        'rozwój BLIKiem — prześlij dowolną kwotę na numer '
                        'telefonu twórcy.',
                        style: TextStyle(fontSize: 14, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: KidsColors.warn.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _copyBlik,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_android,
                                  color: KidsColors.warn,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        _blikDisplay,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: KidsColors.ink,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Text(
                                        'Tap, aby skopiować',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: KidsColors.ink
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.content_copy,
                                  size: 18,
                                  color: KidsColors.warn,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  icon: Icons.mail_outline,
                  title: 'Kontakt',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: _openPlainEmail,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.alternate_email, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _contactEmail,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: KidsColors.seed,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: KidsColors.seed,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: KidsColors.ink.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: KidsColors.ink.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aplikacja nie zbiera żadnych danych osobowych. '
                          'Postęp nauki i statystyki są przechowywane '
                          'lokalnie na urządzeniu.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: KidsColors.ink.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.child,
    this.accent,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? KidsColors.ink;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
