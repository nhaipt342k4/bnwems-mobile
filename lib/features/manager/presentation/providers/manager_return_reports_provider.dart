import 'package:flutter/material.dart';
import '../../data/models/collected_equipment_report.dart';
import '../../data/services/manager_inventory_service.dart';

class ManagerReturnReportsProvider extends ChangeNotifier {
  final ManagerInventoryService _service;

  bool _isLoading = true;
  String? _errorMessage;
  List<CollectedEquipmentReport> _reports = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CollectedEquipmentReport> get reports => _reports;

  ManagerReturnReportsProvider({ManagerInventoryService? service})
      : _service = service ?? ManagerInventoryService();

  Future<void> fetchReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getReturnReports();
      _reports = data.where((r) => r.reportType == 'INTERNAL').toList();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }
}
