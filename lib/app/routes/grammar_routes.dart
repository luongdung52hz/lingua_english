import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';

import '../../presentation/screens/grammar/grammar_detail_screen.dart';
import '../../presentation/screens/grammar/grammar_list_topics_screen.dart';
import '../../presentation/screens/grammar/grammar_topics_screen.dart';

import 'route_names.dart';

List<RouteBase> grammarRoutes(AuthController session) => [
  GoRoute(
    path: Routes.grammar,
    builder: (context, state) {
      return GrammarTopicsScreen(); // Cấp 1: Danh sách topics
    },
    routes: [
      GoRoute(
        path:
            'subtopics/:topicId', // ✅ THÊM: Route mới cho cấp 2 - danh sách subtopics
        builder: (context, state) {
          return GrammarSubTopicsScreen(
            topicId: state.pathParameters['topicId']!,
          );
        },
      ),
      GoRoute(
        path: 'detail/:topicId/:subTopicId', // Cấp 3: Chi tiết sections
        builder: (context, state) {
          return GrammarDetailScreen(
            topicId: state.pathParameters['topicId']!,
            subTopicId: state.pathParameters['subTopicId']!,
          );
        },
      ),
    ],
  ),
];
