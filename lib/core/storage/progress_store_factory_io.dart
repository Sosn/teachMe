import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';
import 'package:teach_me/core/storage/progress_store.dart';

/// Implementacja JSON-plikowa. Jeden plik `progress.json` w
/// `applicationSupportDirectory`. Każda operacja zapisu to pełny rewrite
/// — nasz wolumen danych (<1 KB) to uzasadnia.
class JsonFileProgressStore implements ProgressStore {
  JsonFileProgressStore(this.file);

  final File file;

  @override
  Future<Map<String, WordProgress>> loadAll() async {
    if (!file.existsSync()) return {};
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return {};
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
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map));
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
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'progress.json'));
  return JsonFileProgressStore(file);
}
