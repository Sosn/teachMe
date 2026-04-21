import 'package:meta/meta.dart';
import 'package:teach_me/core/content/ortho_rule.dart';
import 'package:teach_me/core/content/orthography_topic.dart';

/// Jedno słowo w bazie treści. Immutable, ładowane z JSON-a w assets/.
///
/// [mask] musi zawierać dokładnie jedno podkreślenie `_`, które reprezentuje
/// lukę do wypełnienia sekwencją [correct] lub [distractor] (1–2 znaki,
/// żeby obsłużyć zarówno pojedyncze litery jak i dwuznaki rz/sz/ch).
@immutable
class Word {
  const Word({
    required this.id,
    required this.text,
    required this.mask,
    required this.correct,
    required this.distractor,
    required this.rule,
    required this.topic,
    required this.exampleHint,
    required this.difficulty,
    this.imageAsset,
    this.exampleSentence,
    this.errorized,
  }) : assert(difficulty >= 1 && difficulty <= 5, 'difficulty ∈ [1..5]');

  /// Tworzy słowo z mapy JSON, dostając topic z kontekstu pliku
  /// (JSON per-słowo nie zawiera topicu — metadata jest w root).
  factory Word.fromJson(
    Map<String, dynamic> json, {
    required OrthographyTopic topic,
  }) {
    return Word(
      id: json['id'] as String,
      text: json['text'] as String,
      mask: json['mask'] as String,
      correct: json['correct'] as String,
      distractor: json['distractor'] as String,
      rule: OrthoRule.fromId(json['rule'] as String),
      topic: topic,
      exampleHint: json['example_hint'] as String,
      difficulty: json['difficulty'] as int,
      imageAsset: json['image_asset'] as String?,
      exampleSentence: json['example_sentence'] as String?,
      errorized: json['errorized'] as String?,
    );
  }

  /// Stabilny identyfikator (slug ASCII bez polskich znaków).
  final String id;

  /// Pełne, poprawnie napisane słowo (np. "wóz").
  final String text;

  /// Słowo z luką, np. "w_z". Dokładnie jedno podkreślenie.
  final String mask;

  /// Sekwencja poprawna w miejscu luki (np. "ó" albo "rz").
  final String correct;

  /// Sekwencja myląca, pokazywana jako alternatywa (np. "u" albo "ż").
  final String distractor;

  /// Reguła ortograficzna wyjaśniająca pisownię.
  final OrthoRule rule;

  /// Kategoria ortograficzna, do której słowo należy — używana do
  /// filtrowania sesji do konkretnego tematu.
  final OrthographyTopic topic;

  /// Przykład zastosowania reguły (np. "wóz → wozu"). Pokazywane po
  /// odpowiedzi jako scaffolding.
  final String exampleHint;

  /// 1 (najłatwiejsze) do 5 (najtrudniejsze).
  final int difficulty;

  /// Ścieżka do ilustracji (transparent PNG) — jeżeli istnieje,
  /// wyświetlana nad maską jako wsparcie pamięci wzrokowej.
  final String? imageAsset;

  /// Zdanie przykładowe zawierające [text] w formie podstawowej,
  /// min. 5 słów. Używane w ćwiczeniu FindError — pokazujemy zdanie
  /// z przekręconą pisownią tego słowa, dziecko tapuje błąd.
  /// Null = słowo nie jest używane w FindError.
  final String? exampleSentence;

  /// Opcjonalna ręcznie zapisana błędna wersja słowa dla FindError.
  /// Domyślnie FindError generuje błąd mechanicznie przez
  /// `replaceFirst(correct, distractor)`, co dla niektórych słów
  /// daje brzydkie wyniki (np. `mąż → mąrz`, `dąb → domb`). Gdy
  /// chcemy naturalniejszy błąd dziecięcy (np. `mąż → mąsz`,
  /// `dąb → domp`) — wpisujemy go tutaj.
  final String? errorized;

  @override
  String toString() => 'Word($id: $text)';
}
