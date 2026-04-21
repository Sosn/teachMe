import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teach_me/core/content/orthography_topic.dart';
import 'package:teach_me/features/about/about_screen.dart';
import 'package:teach_me/features/category_picker/category_picker_screen.dart';
import 'package:teach_me/features/exercise/exercise_screen.dart';
import 'package:teach_me/features/stats/stats_screen.dart';
import 'package:teach_me/features/subject_picker/subject_picker_screen.dart';

class Routes {
  /// Root — ekran wyboru przedmiotu.
  static const subjects = '/';

  /// Ekran wyboru kategorii w ortografii (ó/u, rz/ż, ch/h, findError).
  static const orthography = '/subject/orthography';

  /// Ekran sesji dla konkretnej kategorii.
  static String orthographyTopic(String topicId) =>
      '/subject/orthography/$topicId';

  /// Ekran statystyk — lista wszystkich kategorii z dwoma wymiarami.
  static const stats = '/stats';

  /// Ekran "O aplikacji" — wejście tylko po parental gate.
  static const about = '/about';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.subjects,
    routes: [
      GoRoute(
        path: Routes.subjects,
        builder: (context, state) => const SubjectPickerScreen(),
      ),
      GoRoute(
        path: Routes.orthography,
        builder: (context, state) => const CategoryPickerScreen(),
      ),
      GoRoute(
        path: '/subject/orthography/:topicId',
        builder: (context, state) {
          final topicId = state.pathParameters['topicId']!;
          final topic = OrthographyTopic.fromId(topicId);
          return ExerciseScreen(topic: topic);
        },
      ),
      GoRoute(
        path: Routes.stats,
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: Routes.about,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
