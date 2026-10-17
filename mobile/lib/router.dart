import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/notes/notes_page.dart';
import 'features/plan/plan_page.dart';
import 'features/plan/plan_tasks_page.dart';
import 'features/projects/project_detail_page.dart';
import 'features/projects/projects_page.dart';
import 'features/settings/settings_page.dart';
import 'features/shell/shell_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;
      final loggedIn = auth.valueOrNull != null;
      final onAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ShellPage(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, __) => const PlanPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (_, __) => const ProjectsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/notes', builder: (_, __) => const NotesPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/projects/:id',
        builder:
            (_, state) => ProjectDetailPage(
              projectId: int.parse(state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/plans/:id/tasks',
        builder:
            (_, state) =>
                PlanTasksPage(planId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
