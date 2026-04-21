import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/stats/category_stats.dart';
import 'package:teach_me/core/stats/stats_snapshot.dart';
import 'package:teach_me/core/stats/stats_store_factory.dart';

/// Persystencja statystyk per kategoria.
///
/// Trzyma dwa "wymiary" dla każdej [OrthographyTopic]:
/// - `lifetime` — kumulatywne, nigdy nie resetowane
/// - `sinceReset` — od ostatniego resetu, resetowane per kategoria
abstract interface class StatsStore {
  Future<StatsSnapshot> load();

  /// Rejestruje ukończoną sesję — dodaje do obu wymiarów (lifetime i
  /// sinceReset) dla wybranej kategorii.
  Future<StatsSnapshot> recordSession(
    OrthographyTopic topic, {
    required int totalQuestions,
    required int correctCount,
    required DateTime at,
  });

  /// Zeruje `sinceReset` dla wybranej kategorii i zapisuje timestamp
  /// w `lastResetAt`. `lifetime` pozostaje nietknięte.
  Future<StatsSnapshot> resetCategory(
    OrthographyTopic topic, {
    required DateTime at,
  });
}

/// Implementacja pamięciowa — na web i testy.
class InMemoryStatsStore implements StatsStore {
  final Map<OrthographyTopic, CategoryStats> _lifetime = {};
  final Map<OrthographyTopic, CategoryStats> _sinceReset = {};
  final Map<OrthographyTopic, DateTime> _lastResetAt = {};

  @override
  Future<StatsSnapshot> load() async => _snapshot();

  @override
  Future<StatsSnapshot> recordSession(
    OrthographyTopic topic, {
    required int totalQuestions,
    required int correctCount,
    required DateTime at,
  }) async {
    _lifetime[topic] = (_lifetime[topic] ?? const CategoryStats()).addSession(
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      at: at,
    );
    _sinceReset[topic] =
        (_sinceReset[topic] ?? const CategoryStats()).addSession(
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      at: at,
    );
    return _snapshot();
  }

  @override
  Future<StatsSnapshot> resetCategory(
    OrthographyTopic topic, {
    required DateTime at,
  }) async {
    _sinceReset[topic] = const CategoryStats();
    _lastResetAt[topic] = at;
    return _snapshot();
  }

  StatsSnapshot _snapshot() => StatsSnapshot(
        lifetime: Map.unmodifiable(_lifetime),
        sinceReset: Map.unmodifiable(_sinceReset),
        lastResetAt: Map.unmodifiable(_lastResetAt),
      );
}

final statsStoreProvider = FutureProvider<StatsStore>((ref) async {
  return createStatsStore();
});

/// Snapshot do obserwacji w UI — po [StatsStore.recordSession] albo
/// [StatsStore.resetCategory] wywołujemy `ref.invalidate(statsSnapshotProvider)`,
/// żeby widget odświeżył dane.
final statsSnapshotProvider = FutureProvider<StatsSnapshot>((ref) async {
  final store = await ref.watch(statsStoreProvider.future);
  return store.load();
});
