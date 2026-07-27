import 'package:flutter/material.dart';
import '../../data/models/work_task_models.dart';
import '../../data/services/schedule_plan_api_service.dart';

class TaskProvider extends ChangeNotifier {
  final SchedulePlanApiService _planApiService;

  List<SchedulePlan> _myPlans = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';

  List<SchedulePlan> get myPlans => _myPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;

  TaskProvider({SchedulePlanApiService? planApiService})
      : _planApiService = planApiService ?? SchedulePlanApiService();

  List<SchedulePlan> getFilteredPlans() {
    return _myPlans.where((plan) {
      final matchesStatus = _selectedStatusFilter == 'ALL' || plan.status == _selectedStatusFilter;
      final keyword = _searchQuery.trim().toLowerCase();
      if (keyword.isEmpty) return matchesStatus;

      final matchesKeyword = plan.taskName.toLowerCase().contains(keyword) ||
          plan.orderCode.toLowerCase().contains(keyword) ||
          (plan.eventName?.toLowerCase().contains(keyword) ?? false);

      return matchesStatus && matchesKeyword;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  SchedulePlan? getPlanById(String planId) {
    try {
      return _myPlans.firstWhere((p) => p.planId == planId);
    } catch (_) {
      return null;
    }
  }

  SchedulePlanAssignee? getMyAssignee(SchedulePlan plan, String userId) {
    try {
      return plan.assignees.firstWhere((a) => a.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMyPlans({String? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plans = await _planApiService.list(assigneeUserId: currentUserId);
      _myPlans = plans;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPlan(String planId) async {
    try {
      final updated = await _planApiService.getById(planId);
      final index = _myPlans.indexWhere((p) => p.planId == planId);
      if (index >= 0) {
        _myPlans[index] = updated;
      } else {
        _myPlans.add(updated);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updatePlanStatus(
    String planId,
    SchedulePlanStatus status, {
    String? notes,
    String? evidenceId,
  }) async {
    final updated = await _planApiService.patchStatus(
      planId,
      status,
      notes: notes,
      evidenceId: evidenceId,
    );
    final index = _myPlans.indexWhere((p) => p.planId == planId);
    if (index >= 0) {
      _myPlans[index] = updated;
    }
    notifyListeners();
  }

  Future<void> checkIn(String planId, String userId, {String? checkInEvidenceId}) async {
    final updated = await _planApiService.checkIn(
      planId,
      userId,
      checkInEvidenceId: checkInEvidenceId,
    );
    final index = _myPlans.indexWhere((p) => p.planId == planId);
    if (index >= 0) {
      _myPlans[index] = updated;
    }
    notifyListeners();
  }

  Future<void> checkOut(String planId, String userId) async {
    final updated = await _planApiService.checkOut(planId, userId);
    final index = _myPlans.indexWhere((p) => p.planId == planId);
    if (index >= 0) {
      _myPlans[index] = updated;
    }
    notifyListeners();
  }

  Future<void> patchEvidence(String planId, String evidenceId) async {
    final updated = await _planApiService.patchEvidence(planId, evidenceId);
    final index = _myPlans.indexWhere((p) => p.planId == planId);
    if (index >= 0) {
      _myPlans[index] = updated;
    }
    notifyListeners();
  }

  Future<void> warehouseMovement(
    String planId,
    List<Map<String, dynamic>> items, {
    String? notes,
  }) async {
    await _planApiService.warehouseMovement(planId, items, notes: notes);
    await refreshPlan(planId);
  }
}
