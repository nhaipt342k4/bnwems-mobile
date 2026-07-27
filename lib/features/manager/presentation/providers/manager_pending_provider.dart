import 'package:flutter/material.dart';
import '../../data/models/pending_summary.dart';
import '../../data/services/manager_pending_service.dart';

enum PendingCategory { all, returnReport, deposit, settlement, changeRequest }

class ManagerPendingProvider extends ChangeNotifier {
  final ManagerPendingService _service;

  bool _isLoading = true;
  String? _errorMessage;

  PendingSummary _summary = PendingSummary.empty();
  PendingCategory _category = PendingCategory.all;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PendingSummary get summary => _summary;
  PendingCategory get category => _category;

  ManagerPendingProvider({ManagerPendingService? service})
      : _service = service ?? ManagerPendingService();

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
}
