import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/core/content/word_repository.dart';
import 'package:teach_me/core/pedagogy/question_selector.dart';
import 'package:teach_me/core/pedagogy/word_progress.dart';
import 'package:teach_me/core/stats/stats_store.dart';
import 'package:teach_me/core/storage/progress_store.dart';
import 'package:teach_me/features/exercise/exercise_type.dart';
import 'package:teach_me/features/exercise/session_state.dart';

/// Długość jednej sesji.
const int _sessionLength = 10;

/// Aktualnie wybrana kategoria. Ustawiana przez CategoryPicker przed
/// nawigacją; ExerciseSessionController ją obserwuje i filtruje słowa.
///
/// Używamy zwykłego StateProvider zamiast family providera, żeby uniknąć
/// problemów z inferencją typów w Riverpod 3.
final currentTopicProvider = StateProvider<OrthographyTopic>(
  (ref) => OrthographyTopic.ouU,
);

/// Controller sesji. Reactively zależny od [currentTopicProvider] — zmiana
/// kategorii powoduje rebuild i nową sesję.
class ExerciseSessionController extends StateNotifier<ExerciseSessionState> {
  ExerciseSessionController(this._ref, this._topic)
      : super(const SessionLoading()) {
    unawaited(_init());
  }

  final Ref _ref;
  final OrthographyTopic _topic;

  Future<void> _init() async {
    final repo = _ref.read(wordRepositoryProvider);
    final topicWords = await repo.loadByTopic(_topic);
    final store = await _ref.read(progressStoreProvider.future);
    final progress = await store.loadAll();

    final random = Random();
    final picked = QuestionSelector.pick(
      allWords: topicWords,
      progressByWordId: progress,
      now: DateTime.now(),
      count: _sessionLength,
      random: random,
    );

    if (picked.isEmpty) {
      state = SessionFinished(topic: _topic, attempts: const []);
      return;
    }

    // Dobór typu zależy od kategorii:
    // - findError: zawsze findError (meta-kategoria).
    // - pozostałe: mix 4 typów, z uwzględnieniem czy słowo ma obrazek.
    final types = [
      for (final w in picked)
        if (_topic == OrthographyTopic.findError)
          ExerciseType.findError
        else
          _randomTypeFor(w.imageAsset != null, random),
    ];

    state = SessionActive(
      topic: _topic,
      words: picked,
      exerciseTypes: types,
      currentIndex: 0,
      attempts: const [],
    );
  }

  Future<void> answer(String letter) async {
    final current = state;
    if (current is! SessionActive || current.isAnswered) return;

    final word = current.currentWord;
    final correct = letter == word.correct;
    final attempt = Attempt(
      wordId: word.id,
      selectedLetter: letter,
      correct: correct,
      at: DateTime.now(),
    );

    state = SessionActive(
      topic: current.topic,
      words: current.words,
      exerciseTypes: current.exerciseTypes,
      currentIndex: current.currentIndex,
      attempts: [...current.attempts, attempt],
      lastAnswerCorrect: correct,
    );

    try {
      final store = await _ref.read(progressStoreProvider.future);
      final all = await store.loadAll();
      final existing = all[word.id] ?? WordProgress(wordId: word.id);
      await store.save(existing.answered(correct: correct, at: attempt.at));
    } on Object catch (_) {
      // brak persystencji nie blokuje ćwiczenia
    }
  }

  void next() {
    final current = state;
    if (current is! SessionActive || !current.isAnswered) return;

    final nextIndex = current.currentIndex + 1;
    if (nextIndex >= current.words.length) {
      final finished = SessionFinished(
        topic: current.topic,
        attempts: current.attempts,
      );
      state = finished;
      // Ukończona sesja → zarejestruj w statystykach (oba wymiary).
      unawaited(_recordStats(finished));
    } else {
      state = SessionActive(
        topic: current.topic,
        words: current.words,
        exerciseTypes: current.exerciseTypes,
        currentIndex: nextIndex,
        attempts: current.attempts,
      );
    }
  }

  /// Zapisuje ukończoną sesję w StatsStore. Błąd zapisu ignorujemy —
  /// gra dalej działa bez persystencji statystyk.
  Future<void> _recordStats(SessionFinished finished) async {
    if (finished.total == 0) return;
    try {
      final store = await _ref.read(statsStoreProvider.future);
      await store.recordSession(
        finished.topic,
        totalQuestions: finished.total,
        correctCount: finished.totalCorrect,
        at: DateTime.now(),
      );
      _ref.invalidate(statsSnapshotProvider);
    } on Object catch (_) {
      // Brak persystencji nie blokuje rozgrywki.
    }
  }

  Future<void> restart() async {
    state = const SessionLoading();
    await _init();
  }
}

/// Wybór typu ćwiczenia dla pojedynczego pytania w normalnej kategorii.
/// Pomija `findError` (osobna meta-kategoria) oraz `spellWord` jeśli
/// słowo nie ma obrazka.
ExerciseType _randomTypeFor(bool hasImage, Random random) {
  final pool = ExerciseType.values.where((t) {
    if (t == ExerciseType.findError) return false;
    if (t == ExerciseType.spellWord && !hasImage) return false;
    return true;
  }).toList();
  return pool[random.nextInt(pool.length)];
}

final exerciseSessionProvider =
    StateNotifierProvider<ExerciseSessionController, ExerciseSessionState>(
  (ref) {
    final topic = ref.watch(currentTopicProvider);
    return ExerciseSessionController(ref, topic);
  },
);
