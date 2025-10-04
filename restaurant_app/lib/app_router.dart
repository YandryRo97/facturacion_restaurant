import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/dashboard_screen.dart';
import 'features/waiter/table_select_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const AuthGate()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const DashboardScreen()),
      GoRoute(path: '/waiter', builder: (c, s) => const TableSelectScreen()),
    ],
  );
});
