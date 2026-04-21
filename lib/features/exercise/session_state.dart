import 'package:meta/meta.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word.dart';
import 'package:teach_me/features/exercise/exercise_type.dart';

/// Jedna odpowiedź dziecka w sesji.
@immutable
class Attempt {
  const Attempt({
    required this.wordId,
    required this.selectedLetter,
    required this.correct,
    required this.at,
  });

  final String wordId;
  final String selectedLetter;
  final bool correct;
  final DateTime at;
}

/// Stan sesji ćwiczenia.
@immutable
sealed class ExerciseSessionState {
  const ExerciseSessionState();
}

class SessionLoading extends ExerciseSessionState {
  const SessionLoading();
}

/// Sesja trwa. Każde słowo ma przypisany [ExerciseType] (mix typów
/// w sesji), ale wszystkie słowa są z jednej kategorii [topic].
@immutable
class SessionActive extends ExerciseSessionState {
  const SessionActive({
    required this.topic,
    required this.words,
    required this.exerciseTypes,
    required this.currentIndex,
    required this.attempts,
    this.lastAnswerCorrect,
  }) : assert(
          words.length == exerciseTypes.length,
          'exerciseTypes musi mieć tę samą długość co words',
        );

  /// Kategoria ortograficzna, w której toczy się sesja.
  final OrthographyTopic topic;
  final List<Word> words;
  final List<ExerciseType> exerciseTypes;
  final int currentIndex;
  final List<Attempt> attempts;
  final bool? lastAnswerCorrect;

  Word get currentWord => words[currentIndex];
  ExerciseType get currentType => exerciseTypes[currentIndex];
  bool get isAnswered => lastAnswerCorrect != null;
  int get totalCorrect => attempts.where((a) => a.correct).length;
}

@immutable
class SessionFinished extends ExerciseSessionState {
  const SessionFinished({required this.topic, required this.attempts});

  final OrthographyTopic topic;
  final List<Attempt> attempts;

  int get total => attempts.length;
  int get totalCorrect => attempts.where((a) => a.correct).length;
  double get accuracy => total == 0 ? 0 : totalCorrect / total;
}
