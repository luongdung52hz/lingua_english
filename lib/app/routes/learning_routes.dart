import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';

import '../../presentation/screens/learn/learn_screen.dart';
import '../../presentation/screens/learn/lesson_detail_screen.dart';

import 'route_names.dart';

List<RouteBase> learningRoutes(AuthController session) => [
  GoRoute(
    path: Routes.learn,
    builder: (context, state) => const LearnScreen(),
    routes: [
      GoRoute(
        path: 'detail/:lessonId',
        builder: (context, state) =>
            LessonDetailScreen(lessonId: state.pathParameters['lessonId']!),
      ),
    ],
  ),
];
