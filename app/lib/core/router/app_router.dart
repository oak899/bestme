import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/daily_plan/daily_plan_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/project_list_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tasks/add_task_screen.dart';
import '../../features/tasks/task_detail_screen.dart';
import '../../providers/app_state.dart';
import '../../screens/ai_plan_screen.dart';

GoRouter createAppRouter(AppState state) => GoRouter(
      refreshListenable: state,
      initialLocation: '/dashboard',
      redirect: (context, goState) {
        print('Router redirect: initialized=${state.initialized}, canUseApp=${state.auth.canUseApp}, isLoggedIn=${state.auth.isLoggedIn}, onLogin=${goState.matchedLocation == "/login"}');
        if (!state.initialized) return null;
        final onLogin = goState.matchedLocation == '/login';
        // Temporarily disable auto-redirect from login page to test manual navigation
        // if (state.auth.canUseApp && onLogin) return '/dashboard';
        if (state.serverSupportsAuth && !state.auth.canUseApp && !onLogin) return '/login';
        return null;
      },
      debugLogDiagnostics: true,
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/tasks/:id', builder: (_, s) => TaskDetailScreen(taskId: s.pathParameters['id']!)),
        GoRoute(path: '/projects/:id', builder: (_, s) => ProjectDetailScreen(projectId: s.pathParameters['id']!)),
        GoRoute(path: '/ai-coach', builder: (_, __) => const AiPlanScreen()),
        GoRoute(path: '/daily-plan', builder: (_, __) => const DailyPlanScreen()),
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/projects', builder: (_, __) => const ProjectListScreen()),
            GoRoute(path: '/add-task', builder: (_, __) => const AddTaskScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    );
