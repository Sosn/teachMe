import 'dart:math' as math;

/// Algorytm Leitnera: 5 pudełek. Poprawna odpowiedź = awans, błąd = powrót
/// do pudełka 1. Odstęp powtórek rośnie wykładniczo z numerem pudełka.
///
/// Dzieciaki klas 1-3 mają krótką pamięć roboczą — częste powtórki w box 1,
/// rzadkie w box 5. Słowa raz opanowane wracają co 14 dni, żeby trzymać je
/// w pamięci długoterminowej.
class LeitnerBox {
  LeitnerBox._();

  static const int minBox = 1;
  static const int maxBox = 5;

  /// Odstępy powtórek w dniach indeksowane numerem pudełka.
  /// Index 0 = nowe/niedotknięte (do nauki dziś).
  static const List<int> intervalDays = [0, 1, 2, 4, 7, 14];

  /// Numer pudełka po odpowiedzi. Błąd zawsze cofa do box 1 (trudne słowa
  /// dostają natychmiastową powtórkę następnego dnia).
  static int nextBox({required int currentBox, required bool correct}) {
    if (!correct) return minBox;
    return math.min(currentBox + 1, maxBox);
  }

  /// Kiedy słowo powinno wrócić do powtórki.
  static DateTime nextReviewAt({
    required int box,
    required DateTime from,
  }) {
    final clamped = box.clamp(0, maxBox);
    return from.add(Duration(days: intervalDays[clamped]));
  }

  /// Czy słowo jest "due" — gotowe do pokazania teraz.
  static bool isDue({
    required int box,
    required DateTime? lastReviewedAt,
    required DateTime now,
  }) {
    if (lastReviewedAt == null) return true; // nowe słowo = zawsze due
    final due = nextReviewAt(box: box, from: lastReviewedAt);
    return !now.isBefore(due);
  }
}
