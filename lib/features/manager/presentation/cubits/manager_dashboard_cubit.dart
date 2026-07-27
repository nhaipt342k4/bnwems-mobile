import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/pending_summary.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_pending_service.dart';
import '../../data/services/manager_schedule_service.dart';
import 'manager_dashboard_state.dart';

class ManagerDashboardCubit extends Cubit<ManagerDashboardState> {
  final ManagerOrderService _orderService;
  final ManagerScheduleService _scheduleService;
  final ManagerPendingService _pendingService;

  ManagerDashboardCubit({
    ManagerOrderService? orderService,
    ManagerScheduleService? scheduleService,
    ManagerPendingService? pendingService,
  })  : _orderService = orderService ?? ManagerOrderService(),
        _scheduleService = scheduleService ?? ManagerScheduleService(),
        _pendingService = pendingService ?? ManagerPendingService(),
        super(ManagerDashboardInitial());

  Future<void> fetchDashboardData() async {
    emit(ManagerDashboardLoading());

    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _orderService.getOrders(limit: 5, orderStatus: 'IN_PROGRESS'),
        _scheduleService.getSchedulePlans(date: todayStr),
        _pendingService.getPendingSummary(),
        _orderService.getOrders(limit: 100),
      ]);

      final upcomingOrders = (results[0] as Map<String, dynamic>)['orders'] as List<dynamic>? ?? [];
      final todaySchedule = (results[1] as List<dynamic>?) ?? [];
      final pendingSummary = results[2] as PendingSummary;
      final allOrdersData = (results[3] as Map<String, dynamic>)['orders'] as List<dynamic>? ?? [];

      final stats = {
        'upcomingOrdersCount': upcomingOrders.length,
        'todayTasksCount': todaySchedule.length,
        'inProgressCount': allOrdersData.where((o) => (o as dynamic).orderStatus == 'IN_PROGRESS').length,
        'pendingCount': pendingSummary.totalCount,
      };

      emit(ManagerDashboardLoaded(
        stats: stats,
        todaySchedule: todaySchedule,
        upcomingOrders: upcomingOrders,
        pendingSummary: pendingSummary,
      ));
    } catch (e) {
      emit(ManagerDashboardError(e.toString()));
    }
  }
}
