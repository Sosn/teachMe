import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/stats/category_stats.dart';
import 'package:teach_me/core/stats/stats_snapshot.dart';
import 'package:teach_me/core/stats/stats_store.dart';

/// Implementacja web — `SharedPreferences` (localStorage pod spodem).
/// Format zapisu taki sam jak `JsonFileStatsStore`, żeby było łatwo
/// migrować między platformami w przyszłości.
class SharedPrefsStatsStore implements StatsStore {
  SharedPrefsStatsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'teachme.stats.v1';

  @override
  Future<StatsSnapshot> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const StatsSnapshot.empty();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _fromJson(json);
  }

  @override
  Future<StatsSnapshot> recordSession(
    OrthographyTopic topic, {
    required int totalQuestions,
    required int correctCount,
    required DateTime at,
  }) async {
    final current = await load();
    final nextLifetime = {...current.lifetime};
    nextLifetime[topic] = current.lifetimeFor(topic).addSession(
          totalQuestions: totalQuestions,
          correctCount: correctCount,
          at: at,
        );
    final nextSinceReset = {...current.sinceReset};
    nextSinceReset[topic] = current.sinceResetFor(topic).addSession(
          totalQuestions: totalQuestions,
          correctCount: correctCount,
          at: at,
        );
    final updated = StatsSnapshot(
      lifetime: nextLifetime,
      sinceReset: nextSinceReset,
      lastResetAt: current.lastResetAt,
    );
    await _persist(updated);
    return updated;
  }

  @override
  Future<StatsSnapshot> resetCategory(
    OrthographyTopic topic, {
    required DateTime at,
  }) async {
    final current = await load();
    final nextSinceReset = {...current.sinceReset};
    nextSinceReset[topic] = const CategoryStats();
    final nextLastResetAt = {...current.lastResetAt};
    nextLastResetAt[topic] = at;
    final updated = StatsSnapshot(
      lifetime: current.lifetime,
      sinceReset: nextSinceReset,
      lastResetAt: nextLastResetAt,
    );
    await _persist(updated);
    return updated;
  }

  Future<void> _persist(StatsSnapshot snapshot) async {
    final json = <String, dynamic>{
      'lifetime': {
        for (final e in snapshot.lifetime.entries) e.key.id: e.value.toJson(),
      },
      'since_reset': {
        for (final e in snapshot.sinceReset.entries) e.key.id: e.value.toJson(),
      },
      'last_reset_at': {
        for (final e in snapshot.lastResetAt.entries)
          e.key.id: e.value.toIso8601String(),
      },
    };
    await _prefs.setString(_key, jsonEncode(json));
  }

  StatsSnapshot _fromJson(Map<String, dynamic> json) {
    return StatsSnapshot(
      lifetime: _topicMap<CategoryStats>(
        json['lifetime'],
        (v) => CategoryStats.fromJson(v! as Map<String, dynamic>),
      ),
      sinceReset: _topicMap<CategoryStats>(
        json['since_reset'],
        (v) => CategoryStats.fromJson(v! as Map<String, dynamic>),
      ),
      lastResetAt: _topicMap<DateTime>(
        json['last_reset_at'],
        (v) => DateTime.parse(v! as String),
      ),
    );
  }

  Map<OrthographyTopic, V> _topicMap<V>(
    Object? raw,
    V Function(Object? value) parseValue,
  ) {
    if (raw == null) return const {};
    final map = raw as Map<String, dynamic>;
    final result = <OrthographyTopic, V>{};
    for (final entry in map.entries) {
      final topic = _safeTopicFromId(entry.key);
      if (topic == null) continue; // nieznany topic w danych → pomijamy
      result[topic] = parseValue(entry.value);
    }
    return result;
  }

  OrthographyTopic? _safeTopicFromId(String id) {
    for (final t in OrthographyTopic.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

Future<StatsStore> createStatsStore() async {
  final prefs = await SharedPreferences.getInstance();
  return SharedPrefsStatsStore(prefs);
}
