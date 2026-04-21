import 'package:meta/meta.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/stats/category_stats.dart';

/// Stan statystyk — dwa wymiary per kategoria:
/// - `lifetime` — kumulatywne, nigdy nie resetowane
/// - `sinceReset` — kumulatywne od ostatniego resetu, resetowane przez
///   użytkownika per kategoria
@immutable
class StatsSnapshot {
  const StatsSnapshot({
    required this.lifetime,
    required this.sinceReset,
    required this.lastResetAt,
  });

  const StatsSnapshot.empty()
      : lifetime = const {},
        sinceReset = const {},
        lastResetAt = const {};

  final Map<OrthographyTopic, CategoryStats> lifetime;
  final Map<OrthographyTopic, CategoryStats> sinceReset;
  final Map<OrthographyTopic, DateTime> lastResetAt;

  CategoryStats lifetimeFor(OrthographyTopic topic) =>
      lifetime[topic] ?? const CategoryStats();

  CategoryStats sinceResetFor(OrthographyTopic topic) =>
      sinceReset[topic] ?? const CategoryStats();

  DateTime? lastResetFor(OrthographyTopic topic) => lastResetAt[topic];
}
