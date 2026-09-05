import '../../presentation/controllers/auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/profile/profile_screen.dart';

import 'route_names.dart';

List<RouteBase> profileRoutes(AuthController session) => [
  GoRoute(
    path: Routes.aiChat,
    builder: (context, state) => const Placeholder(),
  ),

  GoRoute(
    path: Routes.profile,
    builder: (context, state) => const ProfileScreen(),
    routes: [
      GoRoute(
        path: 'settings',
        builder: (context, state) => const Placeholder(),
      ),
    ],
  ),
];
