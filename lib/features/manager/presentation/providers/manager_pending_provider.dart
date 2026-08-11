import 'package:flutter/material.dart';
import '../../data/models/pending_summary.dart';
import '../../data/services/manager_pending_service.dart';
import '../../data/services/manager_survey_service.dart';

enum PendingCategory { all, returnReport, deposit, settlement, changeRequest, survey }

class ManagerPendingProvider extends ChangeNotifier {
  final ManagerPendingService _service;
  final ManagerSurveyService _surveyService;

  bool _isLoading = true;
  String? _errorMessage;

  PendingSummary _summary = PendingSummary.empty();
  PendingCategory _category = PendingCategory.all;
  String? _busyId;
  String? _actionError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PendingSummary get summary => _summary;
  PendingCategory get category => _category;
  String? get busyId => _busyId;
  String? get actionError => _actionError;

  ManagerPendingProvider({ManagerPendingService? service, ManagerSurveyService? surveyService})
      : _service = service ?? ManagerPendingService(),
        _surveyService = surveyService ?? ManagerSurveyService();

  void setCategory(PendingCategory cat) {
    _category = cat;
    notifyListeners();
  }

  Future<void> fetchPendingSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _service.getPendingSummary();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Manager xác nhận 1 khảo sát ngay tại hàng chờ, xong nạp lại danh sách.
  Future<bool> confirmSurvey(String surveyId) async {
    _busyId = surveyId;
    _actionError = null;
    notifyListeners();
    try {
      await _surveyService.confirmSurvey(surveyId);
      _summary = await _service.getPendingSummary();
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
}
