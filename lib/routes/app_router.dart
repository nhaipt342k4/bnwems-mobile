import 'package:go_router/go_router.dart';
import '../features/attendance/presentation/pages/attendance_history_screen.dart';
import '../features/authentication/presentation/pages/login_screen.dart';
import '../features/authentication/presentation/pages/forgot_password_screen.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import '../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../features/notifications/presentation/pages/notification_detail_screen.dart';
import '../features/notifications/presentation/pages/notifications_screen.dart';
import '../features/profile/presentation/pages/profile_screen.dart';
import '../features/profile/presentation/pages/edit_profile_screen.dart';
import '../features/profile/presentation/pages/change_password_screen.dart';
import '../features/schedule/presentation/pages/schedule_calendar_screen.dart';
import '../features/tasks/presentation/pages/task_detail_screen.dart';
import '../features/tasks/presentation/pages/task_list_screen.dart';
import '../features/team/presentation/pages/team_roster_screen.dart';
import '../features/manager/presentation/widgets/manager_layout.dart';
import '../features/manager/presentation/pages/manager_dashboard_screen.dart';
import '../features/manager/presentation/pages/manager_order_list_screen.dart';
import '../features/manager/presentation/pages/manager_order_detail_screen.dart';
import '../features/manager/presentation/pages/manager_deposit_detail_screen.dart';
import '../features/manager/presentation/pages/manager_settlement_detail_screen.dart';
import '../features/manager/presentation/pages/manager_change_requests_screen.dart';
import '../features/manager/presentation/pages/manager_pending_screen.dart';
import '../features/manager/presentation/pages/manager_schedule_screen.dart';
import '../features/manager/presentation/pages/manager_return_reports_screen.dart';
import '../features/manager/presentation/pages/manager_return_report_detail_screen.dart';
import '../features/manager/presentation/pages/manager_plan_detail_screen.dart';
import '../features/manager/presentation/pages/manager_profile_screen.dart';
import '../features/manager/presentation/pages/manager_notifications_screen.dart';
import '../shared/main_layout.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final isLoggingIn = state.matchedLocation == '/auth/login' || state.matchedLocation == '/auth/forgot-password';

      if (status == AuthStatus.uninitialized) return null;

      if (status == AuthStatus.unauthenticated && !isLoggingIn) {
        return '/auth/login';
      }

      if (status == AuthStatus.authenticated && isLoggingIn) {
        final user = authProvider.user;
        if (user != null && user.isManager) {
          return '/manager/dashboard';
        }
        return '/staff/dashboard';
      }

      // Role Guard: Manager routes require manager role
      if (state.matchedLocation.startsWith('/manager')) {
        final user = authProvider.user;
        if (user == null || !user.isManager) {
          return '/staff/dashboard';
        }
      }

      // Role Guard: /staff/team is only for LEAD role
      if (state.matchedLocation == '/staff/team') {
        final user = authProvider.user;
        if (user == null || !user.isLead) {
          return '/staff/profile';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/staff/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/staff/tasks',
            builder: (context, state) => const TaskListScreen(),
          ),
          GoRoute(
            path: '/staff/schedule',
            builder: (context, state) => const ScheduleCalendarScreen(),
          ),
          GoRoute(
            path: '/staff/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/staff/attendance',
            builder: (context, state) => const AttendanceHistoryScreen(),
          ),
          GoRoute(
            path: '/staff/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/staff/tasks/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailScreen(planId: id);
        },
      ),
      GoRoute(
        path: '/staff/team',
        builder: (context, state) => const TeamRosterScreen(),
      ),
      GoRoute(
        path: '/staff/notifications/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NotificationDetailScreen(notificationId: id);
        },
      ),
      GoRoute(
        path: '/staff/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/staff/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Manager Shell Routes & Pages
      ShellRoute(
        builder: (context, state, child) => ManagerLayout(child: child),
        routes: [
          GoRoute(
            path: '/manager/dashboard',
            builder: (context, state) => const ManagerDashboardScreen(),
          ),
          GoRoute(
            path: '/manager/schedule',
            builder: (context, state) => const ManagerScheduleScreen(),
          ),
          GoRoute(
            path: '/manager/orders',
            builder: (context, state) => const ManagerOrderListScreen(),
          ),
          GoRoute(
            path: '/manager/pending',
            builder: (context, state) => const ManagerPendingScreen(),
          ),
          GoRoute(
            path: '/manager/profile',
            builder: (context, state) => const ManagerProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/manager/orders/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ManagerOrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/manager/deposits/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ManagerDepositDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/manager/settlements/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ManagerSettlementDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/manager/change-requests',
        builder: (context, state) => const ManagerChangeRequestsScreen(),
      ),
      GoRoute(
        path: '/manager/returns',
        builder: (context, state) => const ManagerReturnReportsScreen(),
      ),
      GoRoute(
        path: '/manager/returns/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ManagerReturnReportDetailScreen(reportId: id);
        },
      ),
      GoRoute(
        path: '/manager/plans/:planId',
        builder: (context, state) {
          final id = state.pathParameters['planId']!;
          return ManagerPlanDetailScreen(planId: id);
        },
      ),
      GoRoute(
        path: '/manager/notifications',
        builder: (context, state) => const ManagerNotificationsScreen(),
      ),
      GoRoute(
        path: '/manager/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/manager/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );
}
