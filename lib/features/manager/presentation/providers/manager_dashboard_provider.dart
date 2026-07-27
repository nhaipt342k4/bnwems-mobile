import 'package:flutter/material.dart';
import '../../data/models/manager_order.dart';
import '../../data/models/manager_schedule_plan.dart';
import '../../data/models/pending_summary.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_schedule_service.dart';
import '../../data/services/manager_pending_service.dart';
import '../../../../core/utils/formatters.dart';

class ManagerDashboardProvider extends ChangeNotifier {
  final ManagerScheduleService _scheduleService;
  final ManagerOrderService _orderService;
  final ManagerPendingService _pendingService;

  bool _isLoading = true;
  String? _errorMessage;

  List<ManagerSchedulePlan> _todayPlans = [];
  List<ManagerOrder> _upcomingOrders = [];
  PendingSummary _pendingSummary = PendingSummary.empty();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ManagerSchedulePlan> get todayPlans => _todayPlans;
  List<ManagerOrder> get upcomingOrders => _upcomingOrders;
  PendingSummary get pendingSummary => _pendingSummary;

  ManagerDashboardProvider({
    ManagerScheduleService? scheduleService,
    ManagerOrderService? orderService,
    ManagerPendingService? pendingService,
  })  : _scheduleService = scheduleService ?? ManagerScheduleService(),
        _orderService = orderService ?? ManagerOrderService(),
        _pendingService = pendingService ?? ManagerPendingService();

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final todayIso = Formatters.toIsoDateOnly(DateTime.now());

      final results = await Future.wait([
        _scheduleService.getSchedulePlans(
          dateFrom: todayIso,
          dateTo: todayIso,
          dateMode: 'plan',
        ),
        _orderService.getOrders(limit: 100),
        _pendingService.getPendingSummary(),
      ]);

      final plans = results[0] as List<ManagerSchedulePlan>;
      final orders = results[1] as List<ManagerOrder>;
      final summary = results[2] as PendingSummary;

      plans.sort((a, b) => a.startTime.compareTo(b.startTime));
      _todayPlans = plans;

      _upcomingOrders = orders
          .where((o) => o.eventDate.compareTo(todayIso) >= 0 && o.orderStatus != 'CANCELLED')
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      _pendingSummary = summary;
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }
}
