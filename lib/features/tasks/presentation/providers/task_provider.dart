import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/work_task_models.dart';
import '../../data/services/schedule_plan_api_service.dart';

class TaskProvider extends ChangeNotifier {
  final SchedulePlanApiService _planApiService;

  List<SchedulePlan> _myPlans = [];
  final Set<String> _confirmedWarehousePlanIds = {};
  final Set<String> _submittedSurveyPlanIds = {};
  final Set<String> _submittedHandoverPlanIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';

  List<SchedulePlan> get myPlans => _myPlans;
  Set<String> get confirmedWarehousePlanIds => _confirmedWarehousePlanIds;
  Set<String> get submittedSurveyPlanIds => _submittedSurveyPlanIds;
  Set<String> get submittedHandoverPlanIds => _submittedHandoverPlanIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;

  TaskProvider({SchedulePlanApiService? planApiService})
      : _planApiService = planApiService ?? SchedulePlanApiService() {
    _loadConfirmedWarehouseState();
  }

  Future<void> _loadConfirmedWarehouseState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final whList = prefs.getStringList('confirmed_wh_plans') ?? [];
      _confirmedWarehousePlanIds.addAll(whList);

      final surveyList = prefs.getStringList('submitted_survey_plans') ?? [];
      _submittedSurveyPlanIds.addAll(surveyList);

      final handoverList = prefs.getStringList('submitted_handover_plans') ?? [];
      _submittedHandoverPlanIds.addAll(handoverList);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveConfirmedWarehouseState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('confirmed_wh_plans', _confirmedWarehousePlanIds.toList());
    } catch (_) {}
  }

  Future<void> _saveSubmittedSurveyState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('submitted_survey_plans', _submittedSurveyPlanIds.toList());
    } catch (_) {}
  }

  Future<void> _saveSubmittedHandoverState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('submitted_handover_plans', _submittedHandoverPlanIds.toList());
    } catch (_) {}
  }

  bool isWarehouseConfirmed(String planId) {
    return _confirmedWarehousePlanIds.contains(planId);
  }

  bool isSurveySubmitted(String planId) {
    return _submittedSurveyPlanIds.contains(planId);
  }

  void markSurveySubmitted(String planId) {
    _submittedSurveyPlanIds.add(planId);
    _saveSubmittedSurveyState();
    notifyListeners();
  }

  bool isHandoverSubmitted(String planId) {
    return _submittedHandoverPlanIds.contains(planId);
  }

  void markHandoverSubmitted(String planId) {
    _submittedHandoverPlanIds.add(planId);
    _saveSubmittedHandoverState();
    notifyListeners();
  }

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

  SchedulePlan? getActiveCheckedInPlan([String? userId]) {
    for (final plan in _myPlans) {
      for (final assignee in plan.assignees) {
        final matchesUser = userId == null || userId.isEmpty || assignee.userId == userId;
        if (matchesUser && assignee.isCheckedIn && !assignee.isCheckedOut) {
          return plan;
        }
      }
    }
    return null;
  }

  /// Lấy các kế hoạch của nhân viên đang đăng nhập. Server tự giới hạn theo token (role STAFF chỉ nhận
  /// lịch của đơn mình được phân công) nên KHÔNG cần truyền id người dùng từ client nữa.
  Future<void> loadMyPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plans = await _planApiService.list();
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

  Future<void> checkIn(
    String planId,
    String userId, {
    String? checkInEvidenceId,
    double? latitude,
    double? longitude,
  }) async {
    final activePlan = getActiveCheckedInPlan(userId);
    if (activePlan != null && activePlan.planId != planId) {
      throw Exception(
        'Bạn đang thực hiện công việc "${activePlan.taskName}" (${activePlan.planCode}) chưa check-out. Vui lòng check-out trước khi check-in công việc mới.',
      );
    }
    final updated = await _planApiService.checkIn(
      planId,
      userId,
      checkInEvidenceId: checkInEvidenceId,
      latitude: latitude,
      longitude: longitude,
    );
    final index = _myPlans.indexWhere((p) => p.planId == planId);
    if (index >= 0) {
      _myPlans[index] = updated;
    }
    notifyListeners();
  }

  Future<void> checkOut(
    String planId,
    String userId, {
    double? latitude,
    double? longitude,
  }) async {
    final updated = await _planApiService.checkOut(
      planId,
      userId,
      latitude: latitude,
      longitude: longitude,
    );
    final index = _myPlans.indexWhere((p) => p.planId == planId);
    if (index >= 0) {
      _myPlans[index] = updated;
    }
    notifyListeners();
  }

  Future<void> patchEvidence(String planId, List<String> evidenceIds) async {
    final updated = await _planApiService.patchEvidence(planId, evidenceIds);
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
    _confirmedWarehousePlanIds.add(planId);
    await _saveConfirmedWarehouseState();
    notifyListeners();
    await refreshPlan(planId);
  }
}
