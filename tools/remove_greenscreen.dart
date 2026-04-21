// Post-process script: removes the chroma-key green background from images
// produced by Nano Banana and writes back real PNGs with alpha channel.
//
// Run from project root:
//   dart run tools/remove_greenscreen.dart            # process default list
//   dart run tools/remove_greenscreen.dart file1 f2…  # process specific files
//
// Detection is based on GREEN DOMINANCE (g - max(r, b)). Catches both the
// bright chroma green and softer green spill on the edges. For transition
// pixels we suppress the green channel down to max(r, b) to remove the tint.
//
// Idempotent: pixels that are already fully transparent are skipped, so
// running the script twice doesn't break already-processed images.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _defaultSources = <String>[
  // Mascot
  'assets/images/mascot/hedgehog_neutral.png',
  'assets/images/mascot/hedgehog_happy.png',
  'assets/images/mascot/hedgehog_sad.png',
  // Word images — ó/u
  'assets/images/words/noz.png',
  'assets/images/words/stol.png',
  'assets/images/words/lod.png',
  'assets/images/words/zarowka.png',
  'assets/images/words/gora.png',
  'assets/images/words/krol.png',
  'assets/images/words/ogorek.png',
  'assets/images/words/chmura.png',
  // Additional word images (appended as we generate new ones)
  'assets/images/words/woz.png',
  'assets/images/words/duch.png',
  'assets/images/words/kula.png',
  'assets/images/words/mucha.png',
  'assets/images/words/buty.png',
  'assets/images/words/pakunek.png',
  'assets/images/words/ogrod.png',
  'assets/images/words/parowka.png',
  'assets/images/words/drzewo.png',
  'assets/images/words/grzyb.png',
  'assets/images/words/rzeka.png',
  'assets/images/words/zaba.png',
  'assets/images/words/morze.png',
  'assets/images/words/roza.png',
  'assets/images/words/chleb.png',
  'assets/images/words/ucho.png',
  'assets/images/words/hak.png',
  'assets/images/words/herbata.png',
  'assets/images/words/choinka.png',
  'assets/images/words/mroz.png',
  'assets/images/words/chomik.png',
  'assets/images/words/chata.png',
  'assets/images/words/chusta.png',
  'assets/images/words/hotel.png',
  'assets/images/words/hulajnoga.png',
  'assets/images/words/bohater.png',
  'assets/images/words/sol.png',
  'assets/images/words/corka.png',
  'assets/images/words/rysunek.png',
  'assets/images/words/ratunek.png',
  'assets/images/words/klasowka.png',
  'assets/images/words/krzak.png',
  'assets/images/words/pszenica.png',
  'assets/images/words/tatus.png',
  'assets/images/words/ksiazka.png',
  'assets/images/words/lozko.png',
  'assets/images/words/podroz.png',
  'assets/images/words/wieza.png',
  'assets/images/words/maz.png',
  'assets/images/words/trzy.png',
  'assets/images/words/dach.png',
  'assets/images/words/kuchnia.png',
  'assets/images/words/hrabia.png',
  'assets/images/words/chrzan.png',
  'assets/images/words/wrzesien.png',
  'assets/images/words/brzuch.png',
  'assets/images/words/druh.png',
  'assets/images/words/pszczola.png',
  'assets/images/words/dol.png',
  'assets/images/words/ksztalt.png',
  'assets/images/words/kocha.png',
  'assets/images/words/hymn.png',
  'assets/images/words/stolow.png',
  'assets/images/words/chlopcow.png',
  'assets/images/words/domow.png',
  'assets/images/words/wszyscy.png',
  'assets/images/words/wahac.png',
'assets/images/ui/sack.png',
  // ao_en
  'assets/images/words/dab.png',
  'assets/images/words/waz_ao.png',
  'assets/images/words/pak.png',
  'assets/images/words/kat.png',
  'assets/images/words/traba.png',
  'assets/images/words/zab.png',
  'assets/images/words/gaska.png',
  'assets/images/words/piec.png',
  'assets/images/words/reka.png',
  'assets/images/words/zeby.png',
  'assets/images/words/ges.png',
  'assets/images/words/ksiega.png',
  'assets/images/words/mieso.png',
  'assets/images/words/tecza.png',
  // sc_nz
  'assets/images/words/snieg.png',
  'assets/images/words/mis.png',
  'assets/images/words/los.png',
  'assets/images/words/jasmin.png',
  'assets/images/words/kon.png',
  'assets/images/words/slon.png',
  'assets/images/words/dlon.png',
  'assets/images/words/ogien.png',
  'assets/images/words/jesien.png',
  'assets/images/words/cma.png',
  'assets/images/words/nic.png',
  'assets/images/words/lokiec.png',
  'assets/images/words/kosc.png',
  'assets/images/words/zrebie.png',
  // ou +50 (Sprint 7 extension) — wyjątki
  'assets/images/words/zolty.png',
  'assets/images/words/zoltko.png',
  'assets/images/words/jaskolka.png',
  'assets/images/words/pszczolka.png',
  'assets/images/words/wrozka.png',
  'assets/images/words/stroz.png',
  'assets/images/words/pioro.png',
  'assets/images/words/piornik.png',
  'assets/images/words/lodz.png',
  'assets/images/words/miod.png',
  'assets/images/words/mozg.png',
  'assets/images/words/bobr.png',
  'assets/images/words/zrodlo.png',
  'assets/images/words/osmy.png',
  'assets/images/words/olowek.png',
  'assets/images/words/krotki.png',
  'assets/images/words/glowka.png',
  // ou — wymiana
  'assets/images/words/plotno.png',
  'assets/images/words/siodmy.png',
  'assets/images/words/wieczor.png',
  'assets/images/words/trojka.png',
  'assets/images/words/czworka.png',
  'assets/images/words/szostka.png',
  'assets/images/words/chor.png',
  'assets/images/words/pokoj.png',
  'assets/images/words/nozka.png',
  'assets/images/words/kolko.png',
  'assets/images/words/gwozdz.png',
  // ou — końcówka -ów
  'assets/images/words/kotow.png',
  'assets/images/words/psow.png',
  'assets/images/words/wilkow.png',
  'assets/images/words/uczniow.png',
  'assets/images/words/lasow.png',
  // ou — końcówka -ówka
  'assets/images/words/lamiglowka.png',
  'assets/images/words/podstawowka.png',
  'assets/images/words/probowka.png',
  // ou — u podstawowe
  'assets/images/words/kubek.png',
  'assets/images/words/ul.png',
  'assets/images/words/muszla.png',
  'assets/images/words/lustro.png',
  'assets/images/words/lupa.png',
  'assets/images/words/truskawka.png',
  'assets/images/words/kukurydza.png',
  // ou — końcówka -unek
  'assets/images/words/kierunek.png',
  'assets/images/words/opatrunek.png',
  'assets/images/words/budynek.png',
  // rz_z +50 (Sprint 7f) — rz po spółgłosce
  'assets/images/words/przedszkole.png',
  'assets/images/words/przystanek.png',
  'assets/images/words/przyroda.png',
  'assets/images/words/skrzydlo.png',
  'assets/images/words/skrzynia.png',
  'assets/images/words/strzala.png',
  'assets/images/words/jarzebina.png',
  'assets/images/words/warzywa.png',
  'assets/images/words/wrzos.png',
  'assets/images/words/brzoza.png',
  'assets/images/words/krzeslo.png',
  'assets/images/words/grzebien.png',
  'assets/images/words/przyjaciolka.png',
  'assets/images/words/krzyzowka.png',
  'assets/images/words/przygoda.png',
  'assets/images/words/grzywa.png',
  'assets/images/words/krzew.png',
  'assets/images/words/grzmot.png',
  'assets/images/words/strzykawka.png',
  'assets/images/words/drzazga.png',
  'assets/images/words/jastrzab.png',
  'assets/images/words/tchorz.png',
  'assets/images/words/grzanka.png',
  'assets/images/words/brzoskwinia.png',
  'assets/images/words/brzuszek.png',
  // rz_z — rz wyjątki/podstawowe
  'assets/images/words/rzezba.png',
  'assets/images/words/rzeznik.png',
  'assets/images/words/rzesa.png',
  'assets/images/words/burza.png',
  'assets/images/words/zmierzch.png',
  'assets/images/words/zorza.png',
  'assets/images/words/orzel.png',
  // rz_z — ż podstawowe
  'assets/images/words/zelazo.png',
  'assets/images/words/zubr.png',
  'assets/images/words/zyrafa.png',
  'assets/images/words/jezyna.png',
  'assets/images/words/zurek.png',
  'assets/images/words/zuraw.png',
  'assets/images/words/zyto.png',
  'assets/images/words/zaluzja.png',
  'assets/images/words/ryz.png',
  'assets/images/words/jezozwierz.png',
  'assets/images/words/zwir.png',
  'assets/images/words/zoladz.png',
  'assets/images/words/zagiel.png',
  'assets/images/words/zonkil.png',
  'assets/images/words/kaluza.png',
  // rz_z — ż wymiana
  'assets/images/words/odwaznik.png',
  'assets/images/words/wazka.png',
  'assets/images/words/druzyna.png',
  // ch_h +50 (Sprint 7g) — ch podstawowe
  'assets/images/words/chlopiec.png',
  'assets/images/words/chochla.png',
  'assets/images/words/choroba.png',
  'assets/images/words/chryzantema.png',
  'assets/images/words/chmiel.png',
  'assets/images/words/chlew.png',
  'assets/images/words/pchla.png',
  'assets/images/words/chabry.png',
  'assets/images/words/rachunek.png',
  'assets/images/words/wachlarz.png',
  'assets/images/words/chochlik.png',
  'assets/images/words/chusteczka.png',
  'assets/images/words/chodnik.png',
  'assets/images/words/mechanik.png',
  'assets/images/words/mech.png',
  'assets/images/words/puch.png',
  'assets/images/words/marchewka.png',
  'assets/images/words/chalka.png',
  'assets/images/words/chrust.png',
  'assets/images/words/schody.png',
  'assets/images/words/muchomor.png',
  'assets/images/words/macocha.png',
  'assets/images/words/kuchenka.png',
  'assets/images/words/pochodnia.png',
  'assets/images/words/suchar.png',
  // ch wymiana
  'assets/images/words/groch.png',
  'assets/images/words/orzech.png',
  'assets/images/words/smiech.png',
  // h obce
  'assets/images/words/hipopotam.png',
  'assets/images/words/hiena.png',
  'assets/images/words/hamak.png',
  'assets/images/words/hokej.png',
  'assets/images/words/helikopter.png',
  'assets/images/words/hiacynt.png',
  'assets/images/words/harfa.png',
  'assets/images/words/harcerz.png',
  'assets/images/words/hamburger.png',
  'assets/images/words/hangar.png',
  'assets/images/words/harmonijka.png',
  'assets/images/words/herb.png',
  'assets/images/words/heban.png',
  'assets/images/words/hokeista.png',
  'assets/images/words/horyzont.png',
  'assets/images/words/hejnal.png',
  'assets/images/words/halka.png',
  'assets/images/words/hustawka.png',
  'assets/images/words/helm.png',
  'assets/images/words/hala.png',
  'assets/images/words/hantel.png',
  // ao_en +50 (Sprint 7h)
  'assets/images/words/laka.png',
  'assets/images/words/galaz.png',
  'assets/images/words/pajak.png',
  'assets/images/words/maka.png',
  'assets/images/words/was.png',
  'assets/images/words/wawoz.png',
  'assets/images/words/zadlo.png',
  'assets/images/words/wstazka.png',
  'assets/images/words/pstrag.png',
  'assets/images/words/piatek.png',
  'assets/images/words/kapiel.png',
  'assets/images/words/babel.png',
  'assets/images/words/bak.png',
  'assets/images/words/piesc.png',
  'assets/images/words/wedka.png',
  'assets/images/words/wegiel.png',
  'assets/images/words/pek.png',
  'assets/images/words/sep.png',
  'assets/images/words/mieta.png',
  'assets/images/words/trabka.png',
  'assets/images/words/paczek.png',
  'assets/images/words/kasek.png',
  'assets/images/words/pepek.png',
  'assets/images/words/kapielisko.png',
  'assets/images/words/wedlina.png',
  'assets/images/words/beben.png',
  'assets/images/words/recznik.png',
  'assets/images/words/wstega.png',
  'assets/images/words/pieta.png',
  'assets/images/words/wedrowiec.png',
  'assets/images/words/pecherzyk.png',
  'assets/images/words/pedzel.png',
  'assets/images/words/cieciwa.png',
  'assets/images/words/chrzastka.png',
  'assets/images/words/obraczka.png',
  'assets/images/words/rekawiczka.png',
  'assets/images/words/wezel.png',
  'assets/images/words/peseta.png',
  'assets/images/words/lad.png',
  'assets/images/words/jezor.png',
  'assets/images/words/glab.png',
  'assets/images/words/klebek.png',
  'assets/images/words/pieniazek.png',
  'assets/images/words/pisklę.png',
  'assets/images/words/prosie.png',
  'assets/images/words/gasienica.png',
  'assets/images/words/raczka.png',
  'assets/images/words/ramie.png',
  // sc_nz +50 (Sprint 7i)
  'assets/images/words/wisnia.png',
  'assets/images/words/sciana.png',
  'assets/images/words/scierka.png',
  'assets/images/words/swinia.png',
  'assets/images/words/swieca.png',
  'assets/images/words/sliwka.png',
  'assets/images/words/slimak.png',
  'assets/images/words/sledz.png',
  'assets/images/words/smietana.png',
  'assets/images/words/smieci.png',
  'assets/images/words/slad.png',
  'assets/images/words/slub.png',
  'assets/images/words/sniezynka.png',
  'assets/images/words/srubokret.png',
  'assets/images/words/swiat.png',
  'assets/images/words/swit.png',
  'assets/images/words/osmiornica.png',
  'assets/images/words/swietlik.png',
  'assets/images/words/tasma.png',
  'assets/images/words/slinka.png',
  'assets/images/words/swistak.png',
  'assets/images/words/scieg.png',
  'assets/images/words/sciolka.png',
  'assets/images/words/pierscien.png',
  'assets/images/words/ciele.png',
  'assets/images/words/cien.png',
  'assets/images/words/ciesla.png',
  'assets/images/words/ciezarowka.png',
  'assets/images/words/ciecz.png',
  'assets/images/words/ciupaga.png',
  'assets/images/words/ciesnina.png',
  'assets/images/words/kamien.png',
  'assets/images/words/jelen.png',
  'assets/images/words/pien.png',
  'assets/images/words/niedzwiedz.png',
  'assets/images/words/nitka.png',
  'assets/images/words/niemowle.png',
  'assets/images/words/nietoperz.png',
  'assets/images/words/siatka.png',
  'assets/images/words/siodlo.png',
  'assets/images/words/siec.png',
  'assets/images/words/sito.png',
  'assets/images/words/sikora.png',
  'assets/images/words/sierpien.png',
  'assets/images/words/zima.png',
  'assets/images/words/zielnik.png',
  'assets/images/words/laznia.png',
  'assets/images/words/blizniak.png',
  'assets/images/words/paznokiec.png',
  'assets/images/words/cwiartka.png',
];

// Tunables. greenDominance = g - max(r, b).
//  >= _fullyTransparent  → alpha 0
//  <= _startEdge         → alpha 255
//  else                  → linearly fading alpha for clean soft edges
const double _fullyTransparent = 50;
const double _startEdge = 10;

int _alphaFor(double greenDom) {
  if (greenDom >= _fullyTransparent) return 0;
  if (greenDom <= _startEdge) return 255;
  final t =
      (greenDom - _startEdge) / (_fullyTransparent - _startEdge);
  return (255 * (1 - t)).round().clamp(0, 255);
}

Future<void> _process(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Skipping (missing): $path');
    return;
  }

  // Nano Banana sometimes saves JPEG despite .png filename.
  final image = img.decodeImage(await file.readAsBytes());
  if (image == null) {
    stderr.writeln('Decode failed: $path');
    return;
  }

  final out = image.numChannels == 4 ? image : image.convert(numChannels: 4);

  var madeTransparent = 0;
  var edgeSoftened = 0;
  var preserved = 0;
  for (final p in out) {
    // Idempotency — don't re-process pixels already fully transparent.
    final currentAlpha = p.a.toInt();
    if (currentAlpha == 0) {
      preserved++;
      continue;
    }

    final r = p.r.toDouble();
    final g = p.g.toDouble();
    final b = p.b.toDouble();
    final greenDom = g - math.max(r, b);
    final alpha = _alphaFor(greenDom);

    if (alpha == 255) continue;

    final despilledG = math.max(r, b);
    p.setRgba(r.round(), despilledG.round(), b.round(), alpha);

    if (alpha == 0) {
      madeTransparent++;
    } else {
      edgeSoftened++;
    }
  }

  await file.writeAsBytes(img.encodePng(out));
  stdout.writeln(
    '$path  →  transparent: $madeTransparent, edge: $edgeSoftened, '
    'preserved: $preserved',
  );
}

Future<void> main(List<String> argv) async {
  final sources = argv.isEmpty ? _defaultSources : argv;
  for (final path in sources) {
    await _process(path);
  }
  stdout.writeln('Done (${sources.length} files).');
}
