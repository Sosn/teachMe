/// Reguły ortograficzne polskie. Każda reguła ma krótki opis pokazywany
/// dziecku po błędzie (scaffolding).
enum OrthoRule {
  // --- ó / u ---
  ouWymianaO(
    'ou_wymiana_o',
    'ó wymienia się na o (np. wóz → wozu)',
  ),
  ouKoncowkaOw(
    'ou_koncowka_ow',
    'końcówka -ów w dopełniaczu liczby mnogiej',
  ),
  ouKoncowkaOwka(
    'ou_koncowka_owka',
    'końcówka -ówka (np. żarówka, klasówka)',
  ),
  ouWyjatek(
    'ou_wyjatek',
    'wyjątek — zapamiętaj, że piszemy przez ó',
  ),
  uPodstawowe(
    'u_podstawowe',
    'zwykłe u, bez reguły wymiany',
  ),
  uKoncowkaUnek(
    'u_koncowka_unek',
    'końcówka -unek (np. rysunek, kierunek)',
  ),
  uKoncowkaUs(
    'u_koncowka_us',
    'końcówka -uś / -usz / -unio (zdrobnienia)',
  ),

  // --- rz / ż ---
  rzPoSpolgl(
    'rz_po_spolgl',
    'rz po spółgłoskach p, b, t, d, k, g, ch, j, w',
  ),
  rzPodstawowe(
    'rz_podstawowe',
    'rz w wyrazie, którego pisowni trzeba się nauczyć (np. rzeka, rzecz)',
  ),
  rzWymianaR(
    'rz_wymiana_r',
    'rz wymienia się na r (np. morze → morski)',
  ),
  rzWyjatek(
    'rz_wyjatek',
    'wyjątek — tu piszemy sz, nie rz (pszenica, kształt)',
  ),
  zPodstawowe(
    'z_podstawowe',
    'ż pisane standardowo (żaba, jeż, mąż)',
  ),
  zWymiana(
    'z_wymiana',
    'ż wymienia się na g lub k (książka → księga)',
  ),

  // --- ch / h ---
  chPodstawowe(
    'ch_podstawowe',
    'ch pisane standardowo (chleb, ucho, mucha)',
  ),
  chWymianaSz(
    'ch_wymiana_sz',
    'ch wymienia się na sz (mucha → muszka)',
  ),
  hPodstawowe(
    'h_podstawowe',
    'h w wyrazach obcych (herbata, hak, hotel)',
  ),
  hWymiana(
    'h_wymiana',
    'h wymienia się na g lub z (druh → drużyna)',
  ),

  // --- ą / ę / on / om / en / em (nosówki) ---
  aoNosowka(
    'ao_nosowka',
    'nosówka — piszemy ą lub ę, choć brzmi jak "on", "om", "en" albo "em"',
  ),
  aoWymianaEa(
    'ao_wymiana_ea',
    'wymiana ą ↔ ę (np. dąb → dęby, ręka → rąk)',
  ),
  aoPrzedPb(
    'ao_przed_pb',
    'przed p/b piszemy ą/ę, choć brzmi jak "om"/"em" (ząb, trąba)',
  ),
  aoBezNosowki(
    'ao_bez_nosowki',
    'tu NIE ma nosówki — piszemy zwykłe a lub e (miał, nie miął)',
  ),

  // --- ś / ć / ń / ź (zmiękczenia) ---
  scMiekka(
    'sc_miekka',
    'miękka spółgłoska — ś, ć, ń, ź (przed spółgłoską i na końcu słowa)',
  ),
  scPrzedSamogl(
    'sc_przed_samogl',
    'przed samogłoską piszemy si, ci, ni, zi (nie ś/ć/ń/ź) — np. ciocia, siano, niebo',
  ),
  scWyjatek(
    'sc_wyjatek',
    'trudne miejsce — ś przed inną miękką spółgłoską (np. prośba, kość)',
  );

  const OrthoRule(this.id, this.hint);

  /// Stabilny identyfikator używany w JSON-ach z treścią i w bazie danych.
  final String id;

  /// Krótki opis pokazywany dziecku (scaffolding, po błędzie).
  final String hint;

  static OrthoRule fromId(String id) => OrthoRule.values.firstWhere(
        (r) => r.id == id,
        orElse: () => throw StateError(
          'Nieznana reguła ortograficzna w JSON-ie: "$id". '
          'Sprawdź assets/content/orthography/*.json oraz enum OrthoRule.',
        ),
      );
}
