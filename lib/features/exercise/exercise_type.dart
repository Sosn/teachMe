/// Typy ćwiczeń dostępne w sesji ortograficznej. Każdy typ jest
/// renderowany przez inny widget, ale działa na tym samym modelu słowa
/// i tej samej logice sesji — różnica jest wyłącznie w UX, co zapobiega
/// nudze przy długich seriach pytań.
enum ExerciseType {
  /// Tap odpowiedniej litery (dwa duże przyciski).
  chooseLetter,

  /// Przeciąganie litery z paska do luki w słowie.
  dragLetter,

  /// Przeciąganie całego słowa do worka z literą — trenuje
  /// kategoryzację wg reguły ortograficznej.
  categorySort,

  /// Układanie CAŁEGO słowa z rozsypanych liter, patrząc na obrazek.
  /// Trenuje produkcję (nie wybór) — dziecko pamięta wzorzec graficzny
  /// słowa, nie tylko jedną "trudną" literę. Wymaga obrazka słowa.
  spellWord,

  /// Znajdź błąd w zdaniu. Zdanie (≥5 słów) zawiera jedno słowo z
  /// nieprawidłową pisownią (correct ↔ distractor); dziecko tapuje
  /// błędne słowo. Trenuje rozpoznawanie błędu w kontekście.
  /// Używane wyłącznie w meta-kategorii `findError`.
  findError,
}
