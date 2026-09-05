import '../di/dependency_injection.dart';
import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/controllers/chat_controller.dart';
import '../../presentation/controllers/friend_controller.dart';
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/chat/friend_screen.dart';

import 'route_names.dart';

List<RouteBase> chatRoutes(AuthController session) => [
  GoRoute(
    path: Routes.chat,
    builder: (context, state) => ChangeNotifierProvider(
      create: (_) => getIt<ChatController>(),
      child: const ChatListScreen(),
    ),
    routes: [
      GoRoute(
        path: 'friends',
        builder: (context, state) => ChangeNotifierProvider<FriendController>(
          create: (_) => getIt<FriendController>(),
          child: FriendsScreen(currentUid: session.userId ?? ''),
        ),
      ),
      GoRoute(
        path: 'room/:roomId',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => getIt<ChatController>(),
          child: ChatScreen(
            roomId: state.pathParameters['roomId']!,
            currentUid: session.userId ?? '',
          ),
        ),
      ),
    ],
  ),
];
