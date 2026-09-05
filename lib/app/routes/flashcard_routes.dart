import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';

import '../../presentation/screens/flashcard/flash_study_screen.dart';
import '../../presentation/screens/flashcard/flash_create_screen.dart';
import '../../presentation/screens/flashcard/flashcard_detail_screen.dart';
import '../../presentation/screens/flashcard/folder_management_screen.dart';
import '../../presentation/screens/flashcard/flashcard_screen.dart';

import 'route_names.dart';

List<RouteBase> flashcardRoutes(AuthController session) => [
  GoRoute(
    path: Routes.flashcards,
    builder: (context, state) => const FlashcardListScreen(),
    routes: [
      GoRoute(
        path: 'detail/:id',
        builder: (context, state) =>
            FlashcardDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'create',
        builder: (context, state) => const FlashcardCreateScreen(),
      ),
      GoRoute(
        path: 'study',
        builder: (context, state) => const FlashcardStudyScreen(),
      ),
      GoRoute(
        path: 'folders',
        builder: (context, state) => const FolderManagementScreen(),
      ),
    ],
  ),
];
