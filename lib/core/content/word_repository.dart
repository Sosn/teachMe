import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word.dart';

/// Loader treści. W produkcji używa `rootBundle` Fluttera; w testach
/// wstrzykujemy własny loader przez `WordRepository.fromLoader`, żeby nie
/// potrzebować Flutter test bindingu.
typedef AssetLoader = Future<String> Function(String assetPath);

class WordRepository {
  /// Konstruktor produkcyjny — czyta z assets/ Fluttera.
  WordRepository() : _load = rootBundle.loadString;

  /// Konstruktor testowy — wstrzykujemy własnego loadera.
  WordRepository.fromLoader(AssetLoader loader) : _load = loader;

  final AssetLoader _load;

  /// Mapowanie: topic → ścieżka JSON. Gdy dodamy kolejny topic,
  /// uzupełniamy enum [OrthographyTopic] i tutaj.
  static const Map<OrthographyTopic, String> _topicAssets = {
    OrthographyTopic.ouU: 'assets/content/orthography/ou.json',
    OrthographyTopic.rzZ: 'assets/content/orthography/rz_z.json',
    OrthographyTopic.chH: 'assets/content/orthography/ch_h.json',
    OrthographyTopic.aoEn: 'assets/content/orthography/ao_en.json',
    OrthographyTopic.scNz: 'assets/content/orthography/sc_nz.json',
  };

  /// Wczytuje wszystkie słowa ze wszystkich kategorii. Posortowane po
  /// difficulty rosnąco, dla stabilnej kolejności.
  Future<List<Word>> loadAll() async {
    final words = <Word>[];
    for (final entry in _topicAssets.entries) {
      words.addAll(await _loadTopic(entry.key, entry.value));
    }
    words.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return words;
  }

  /// Wczytuje słowa tylko z wybranej kategorii.
  ///
  /// Dla [OrthographyTopic.findError] (meta-kategoria) zwracamy słowa ze
  /// WSZYSTKICH tematów ortograficznych, ale tylko te które mają
  /// `exampleSentence` — tylko one nadają się do ćwiczenia "znajdź błąd".
  Future<List<Word>> loadByTopic(OrthographyTopic topic) async {
    if (topic == OrthographyTopic.findError) {
      final all = await loadAll();
      return all.where((w) => w.exampleSentence != null).toList();
    }
    final path = _topicAssets[topic];
    if (path == null) return const [];
    final words = await _loadTopic(topic, path);
    words.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return words;
  }

  Future<List<Word>> _loadTopic(OrthographyTopic topic, String asset) async {
    final raw = await _load(asset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['words'] as List).cast<Map<String, dynamic>>();
    return list.map((w) => Word.fromJson(w, topic: topic)).toList();
  }
}

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepository();
});
