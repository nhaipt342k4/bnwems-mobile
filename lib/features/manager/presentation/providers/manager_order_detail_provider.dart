import 'package:flutter/material.dart';
import '../../data/models/manager_order.dart';
import '../../data/models/deposit.dart';
import '../../data/models/settlement.dart';
import '../../data/models/manager_schedule_plan.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_deposit_service.dart';
import '../../data/services/manager_settlement_service.dart';
import '../../data/services/manager_schedule_service.dart';

class ManagerOrderDetailProvider extends ChangeNotifier {
  final ManagerOrderService _orderService;
  final ManagerDepositService _depositService;
  final ManagerSettlementService _settlementService;
  final ManagerScheduleService _scheduleService;

  bool _isLoading = true;
  bool _isCancelling = false;
  String? _errorMessage;
  String? _cancelError;

  ManagerOrder? _order;
  List<Deposit> _deposits = [];
  Settlement? _settlement;
  List<ManagerSchedulePlan> _plans = [];

  bool get isLoading => _isLoading;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  String? get cancelError => _cancelError;

  ManagerOrder? get order => _order;
  List<Deposit> get deposits => _deposits;
  Deposit? get latestDeposit => _deposits.isNotEmpty ? _deposits.first : null;
  Settlement? get settlement => _settlement;
  List<ManagerSchedulePlan> get plans => _plans;

  ManagerOrderDetailProvider({
    ManagerOrderService? orderService,
    ManagerDepositService? depositService,
    ManagerSettlementService? settlementService,
    ManagerScheduleService? scheduleService,
  })  : _orderService = orderService ?? ManagerOrderService(),
        _depositService = depositService ?? ManagerDepositService(),
        _settlementService = settlementService ?? ManagerSettlementService(),
        _scheduleService = scheduleService ?? ManagerScheduleService();

  Future<void> loadOrderDetail(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _orderService.getOrder(orderId),
        _depositService.getOrderDeposits(orderId),
        _settlementService.getOrderSettlement(orderId),
        _scheduleService.getSchedulePlans(orderId: orderId),
      ]);

      _order = results[0] as ManagerOrder;
      _deposits = results[1] as List<Deposit>;
      _settlement = results[2] as Settlement?;
      final rawPlans = results[3] as List<ManagerSchedulePlan>;
      rawPlans.sort((a, b) => a.startTime.compareTo(b.startTime));
      _plans = rawPlans;

      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    if (reason.trim().isEmpty) {
      _cancelError = 'Vui lòng nhập lý do hủy đơn.';
      notifyListeners();
      return false;
    }

    _isCancelling = true;
    _cancelError = null;
    notifyListeners();

    try {
      _order = await _orderService.updateOrderStatus(
        orderId,
        orderStatus: 'CANCELLED',
        cancelReason: reason,
      );
      _isCancelling = false;
      notifyListeners();
      return true;
    } catch (e) {
      _cancelError = e.toString().replaceAll('Exception: ', '');
      _isCancelling = false;
      notifyListeners();
      return false;
    }
  }
}
