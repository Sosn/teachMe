import 'package:meta/meta.dart';

/// Agregaty per kategoria — akumulowane niemutowalnie.
@immutable
class CategoryStats {
  const CategoryStats({
    this.sessions = 0,
    this.questions = 0,
    this.correct = 0,
    this.lastSessionAt,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    final last = json['last_session_at'] as String?;
    return CategoryStats(
      sessions: json['sessions'] as int? ?? 0,
      questions: json['questions'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      lastSessionAt: last == null ? null : DateTime.parse(last),
    );
  }

  final int sessions;
  final int questions;
  final int correct;
  final DateTime? lastSessionAt;

  int get incorrect => questions - correct;

  /// Trafność w zakresie 0..1 (0 dla pustej historii).
  double get accuracy => questions == 0 ? 0 : correct / questions;

  /// Dodaje jedną ukończoną sesję do statystyk. Zwraca nowy [CategoryStats].
  CategoryStats addSession({
    required int totalQuestions,
    required int correctCount,
    required DateTime at,
  }) {
    return CategoryStats(
      sessions: sessions + 1,
      questions: questions + totalQuestions,
      correct: correct + correctCount,
      lastSessionAt: at,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessions': sessions,
        'questions': questions,
        'correct': correct,
        'last_session_at': lastSessionAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is CategoryStats &&
      other.sessions == sessions &&
      other.questions == questions &&
      other.correct == correct &&
      other.lastSessionAt == lastSessionAt;

  @override
  int get hashCode =>
      Object.hash(sessions, questions, correct, lastSessionAt);
}
