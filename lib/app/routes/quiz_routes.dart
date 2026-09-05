import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';
import 'package:learn_english/presentation/screens/quiz/quiz_create_screen.dart';
import 'package:learn_english/presentation/screens/quiz/quiz_detail_screen.dart';
import 'package:learn_english/presentation/screens/quiz/quiz_list_screen.dart';

import '../../presentation/screens/quiz/widgets/quiz_taking.dart';

import 'route_names.dart';

List<RouteBase> quizRoutes(AuthController session) => [
  GoRoute(
    path: Routes.quiz,
    builder: (context, state) => QuizListScreen(),
    routes: [
      GoRoute(
        path: 'detail/:id',
        builder: (context, state) =>
            QuizDetailScreen(quizId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'taking/:id',
        builder: (context, state) =>
            QuizTakingScreen(quizId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'create',
        builder: (context, state) => const CreateQuizScreen(),
      ),
    ],
  ),
];
