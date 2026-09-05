import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/admin/admin_screen.dart';

import 'route_names.dart';

List<RouteBase> dashboardRoutes(AuthController session) => [
  GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
  GoRoute(path: Routes.admin, builder: (context, state) => const AdminScreen()),
];
