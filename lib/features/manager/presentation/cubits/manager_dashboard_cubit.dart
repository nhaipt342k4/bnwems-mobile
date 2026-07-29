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
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    List<dynamic> upcomingOrders = [];
    List<dynamic> todaySchedule = [];
    PendingSummary pendingSummary = PendingSummary.empty();
    List<dynamic> allOrdersData = [];

    void emitCurrent() {
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
    }

    // 1. Pending Summary (Fastest)
    _pendingService.getPendingSummary().then((summary) {
      pendingSummary = summary;
      emitCurrent();
    }).catchError((_) {});

    // 2. Today Schedule
    _scheduleService.getSchedulePlans(date: todayStr).then((schedule) {
      todaySchedule = schedule;
      emitCurrent();
    }).catchError((_) {});

    // 3. Upcoming Orders
    _orderService.getOrders(limit: 5, orderStatus: 'IN_PROGRESS').then((orders) {
      upcomingOrders = orders;
      emitCurrent();
    }).catchError((_) {});

    // 4. All Orders (For stats)
    _orderService.getOrders(limit: 100).then((orders) {
      allOrdersData = orders;
      emitCurrent();
    }).catchError((_) {});
  }
}
