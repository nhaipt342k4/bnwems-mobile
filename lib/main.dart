import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/cubits/auth_cubit.dart';
import 'features/authentication/presentation/providers/auth_provider.dart';
import 'features/manager/presentation/cubits/manager_dashboard_cubit.dart';
import 'features/manager/presentation/providers/manager_change_requests_provider.dart';
import 'features/manager/presentation/providers/manager_dashboard_provider.dart';
import 'features/manager/presentation/providers/manager_deposit_provider.dart';
import 'features/manager/presentation/providers/manager_order_detail_provider.dart';
import 'features/manager/presentation/providers/manager_order_list_provider.dart';
import 'features/manager/presentation/providers/manager_pending_provider.dart';
import 'features/manager/presentation/providers/manager_return_report_detail_provider.dart';
import 'features/manager/presentation/providers/manager_return_reports_provider.dart';
import 'features/manager/presentation/providers/manager_schedule_provider.dart';
import 'features/manager/presentation/providers/manager_settlement_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/tasks/presentation/providers/task_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FcmService().initialize();
  runApp(const BnwemsStaffApp());
}

class BnwemsStaffApp extends StatelessWidget {
  const BnwemsStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkAuthStatus()),
        BlocProvider(create: (_) => ManagerDashboardCubit()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ManagerDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ManagerOrderListProvider()),
        ChangeNotifierProvider(create: (_) => ManagerOrderDetailProvider()),
        ChangeNotifierProvider(create: (_) => ManagerDepositProvider()),
        ChangeNotifierProvider(create: (_) => ManagerSettlementProvider()),
        ChangeNotifierProvider(create: (_) => ManagerChangeRequestsProvider()),
        ChangeNotifierProvider(create: (_) => ManagerPendingProvider()),
        ChangeNotifierProvider(create: (_) => ManagerScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ManagerReturnReportsProvider()),
        ChangeNotifierProvider(create: (_) => ManagerReturnReportDetailProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final router = createRouter(authProvider);
          return MaterialApp.router(
            title: 'BNWEMS Staff',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
