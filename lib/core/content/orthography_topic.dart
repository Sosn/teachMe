import 'package:flutter/widgets.dart';

/// Kategorie ortograficzne dostępne w aplikacji. Każda kategoria ma
/// osobny plik JSON z treścią i odpowiadający ekran wyboru.
///
/// [id] — stabilny identyfikator (zgodny z polem "topic" w JSON i z
/// segmentem URL). [label] — polska nazwa do UI.
enum OrthographyTopic {
  ouU('ou', 'ó / u', 'ó/u', Color(0xFF3B82F6)),
  rzZ('rz_z', 'rz / ż', 'rz/ż', Color(0xFFF97316)),
  chH('ch_h', 'ch / h', 'ch/h', Color(0xFF22C55E)),
  aoEn('ao_en', 'ą / ę', 'ą/ę', Color(0xFFEC4899)),
  scNz('sc_nz', 'ś / ć / ń / ź', 'śćńź', Color(0xFFEAB308)),

  /// Meta-kategoria — słowa ze wszystkich tematów, prezentowane
  /// jako zdania z błędem do znalezienia.
  findError('find_error', 'Poprawianie tekstu', 'błąd', Color(0xFFA855F7));

  const OrthographyTopic(this.id, this.label, this.shortLabel, this.accent);

  final String id;

  /// Pełna nazwa dla list i nagłówków.
  final String label;

  /// Krótki skrót (max ~4 znaki) dla badge'ów, kwadratowych ikon,
  /// wąskich kontenerów. Używamy w CategoryPicker i StatsScreen.
  final String shortLabel;

  final Color accent;

  static OrthographyTopic fromId(String id) =>
      OrthographyTopic.values.firstWhere(
        (t) => t.id == id,
        orElse: () => throw StateError(
          'Nieznana kategoria ortograficzna: "$id". '
          'Sprawdź router, linki i enum OrthographyTopic.',
        ),
      );
}
