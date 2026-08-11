import 'package:flutter/material.dart';
import '../../data/models/manager_schedule_plan.dart';
import '../../data/models/deposit.dart';
import '../../data/models/settlement.dart';
import '../../data/models/collected_equipment_report.dart';
import '../../data/models/change_request.dart';
import '../../data/services/manager_schedule_service.dart';
import '../../data/services/manager_deposit_service.dart';
import '../../data/services/manager_settlement_service.dart';
import '../../data/services/manager_inventory_service.dart';
import '../../data/services/manager_change_request_service.dart';

/// Nạp 1 schedule plan + các báo cáo do staff đã nhập (theo orderId) để manager XEM + DUYỆT tại chỗ:
/// cọc hiện trường, quyết toán, thu hồi kho, yêu cầu đổi thiết bị.
class ManagerPlanDetailProvider extends ChangeNotifier {
  final ManagerScheduleService _scheduleService;
  final ManagerDepositService _depositService;
  final ManagerSettlementService _settlementService;
  final ManagerInventoryService _inventoryService;
  final ManagerChangeRequestService _changeRequestService;

  ManagerPlanDetailProvider({
    ManagerScheduleService? scheduleService,
    ManagerDepositService? depositService,
    ManagerSettlementService? settlementService,
    ManagerInventoryService? inventoryService,
    ManagerChangeRequestService? changeRequestService,
  })  : _scheduleService = scheduleService ?? ManagerScheduleService(),
        _depositService = depositService ?? ManagerDepositService(),
        _settlementService = settlementService ?? ManagerSettlementService(),
        _inventoryService = inventoryService ?? ManagerInventoryService(),
        _changeRequestService = changeRequestService ?? ManagerChangeRequestService();

  bool _isLoading = true;
  String? _errorMessage;
  ManagerSchedulePlan? _plan;
  List<Deposit> _deposits = [];
  Settlement? _settlement;
  List<CollectedEquipmentReport> _returnReports = [];
  List<ChangeRequest> _changeRequests = [];
  String? _busyId; // id item đang xử lý (để disable đúng nút)
  String? _actionError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ManagerSchedulePlan? get plan => _plan;
  List<Deposit> get deposits => _deposits;
  Settlement? get settlement => _settlement;
  List<CollectedEquipmentReport> get returnReports => _returnReports;
  List<ChangeRequest> get changeRequests => _changeRequests;
  String? get busyId => _busyId;
  String? get actionError => _actionError;

  Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _reloadReports(String orderId) async {
    _deposits = await _safe(() => _depositService.getOrderDeposits(orderId), <Deposit>[]);
    _settlement = await _safe(() => _settlementService.getOrderSettlement(orderId), null);
    _returnReports = await _safe(() => _inventoryService.getReturnReports(orderId: orderId), <CollectedEquipmentReport>[]);
    _changeRequests = await _safe(() => _changeRequestService.getChangeRequests(orderId: orderId), <ChangeRequest>[]);
  }

  Future<void> load(String planId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _plan = await _scheduleService.getSchedulePlanById(planId);
      await _reloadReports(_plan!.orderId);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> _run(String id, Future<void> Function() action) async {
    _busyId = id;
    _actionError = null;
    notifyListeners();
    try {
      await action();
      if (_plan != null) await _reloadReports(_plan!.orderId);
      _busyId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString().replaceAll('Exception: ', '');
      _busyId = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmDeposit(String depositId) =>
      _run(depositId, () => _depositService.updateDepositStatus(depositId, status: 'PAID'));

  Future<bool> confirmReturn(String reportId) =>
      _run(reportId, () => _inventoryService.confirmReturnReport(reportId));

  /// status = 'approved' | 'rejected'
  Future<bool> decideChangeRequest(String id, String status) =>
      _run(id, () => _changeRequestService.approveChangeRequest(id, status));
}
