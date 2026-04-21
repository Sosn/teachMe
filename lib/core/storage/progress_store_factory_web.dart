import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';
import 'package:teach_me/core/storage/progress_store.dart';

/// Implementacja web używająca `SharedPreferences`, które na web
/// delegują do `window.localStorage`. Dzięki temu progres przeżywa
/// odświeżenie strony / restart aplikacji (wcześniej był in-memory).
///
/// Format zapisu jest kompatybilny z `JsonFileProgressStore` — ten sam
/// schemat per-słowo. Zachowujemy wersję w nazwie klucza, żeby przy
/// ewentualnej migracji mieć czystą drogę.
class SharedPrefsProgressStore implements ProgressStore {
  SharedPrefsProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'teachme.progress.v1';

  @override
  Future<Map<String, WordProgress>> loadAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return {};
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map(
      (key, value) =>
          MapEntry(key, _fromJson(key, value as Map<String, dynamic>)),
    );
  }

  @override
  Future<void> save(WordProgress progress) async {
    final all = await loadAll();
    all[progress.wordId] = progress;
    await saveAll(all.values);
  }

  @override
  Future<void> saveAll(Iterable<WordProgress> progresses) async {
    final map = {
      for (final p in progresses) p.wordId: _toJson(p),
    };
    await _prefs.setString(_key, jsonEncode(map));
  }

  @override
  Future<void> removeMany(Iterable<String> wordIds) async {
    final all = await loadAll();
    wordIds.forEach(all.remove);
    await saveAll(all.values);
  }

  Map<String, dynamic> _toJson(WordProgress p) => {
        'box': p.box,
        'last_reviewed_at': p.lastReviewedAt?.toIso8601String(),
        'correct_count': p.correctCount,
        'incorrect_count': p.incorrectCount,
      };

  WordProgress _fromJson(String wordId, Map<String, dynamic> json) {
    final last = json['last_reviewed_at'] as String?;
    return WordProgress(
      wordId: wordId,
      box: json['box'] as int,
      lastReviewedAt: last == null ? null : DateTime.parse(last),
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
    );
  }
}

Future<ProgressStore> createProgressStore() async {
  final prefs = await SharedPreferences.getInstance();
  return SharedPrefsProgressStore(prefs);
}
