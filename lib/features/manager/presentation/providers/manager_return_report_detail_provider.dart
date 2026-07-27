import 'package:flutter/material.dart';
import '../../data/models/collected_equipment_report.dart';
import '../../data/models/inventory.dart';
import '../../data/services/manager_inventory_service.dart';

class ManagerReturnReportDetailProvider extends ChangeNotifier {
  final ManagerInventoryService _service;

  bool _isLoading = true;
  bool _isConfirming = false;
  String? _errorMessage;
  bool _showNotice = false;

  CollectedEquipmentReport? _report;
  Map<String, InventoryRow> _inventoryByItem = {};

  bool get isLoading => _isLoading;
  bool get isConfirming => _isConfirming;
  String? get errorMessage => _errorMessage;
  bool get showNotice => _showNotice;

  CollectedEquipmentReport? get report => _report;
  Map<String, InventoryRow> get inventoryByItem => _inventoryByItem;

  bool get isConfirmed => _report?.status == 'CONFIRMED';

  ManagerReturnReportDetailProvider({ManagerInventoryService? service})
      : _service = service ?? ManagerInventoryService();

  void toggleNotice() {
    _showNotice = !_showNotice;
    notifyListeners();
  }

  Map<String, int> get totals {
    if (_report == null) return {'good': 0, 'damaged': 0, 'lost': 0, 'total': 0};
    int good = 0, damaged = 0, lost = 0;
    for (final item in _report!.items) {
      good += item.goodQuantity;
      damaged += item.damagedQuantity;
      lost += item.lostQuantity;
    }
    return {
      'good': good,
      'damaged': damaged,
      'lost': lost,
      'total': good + damaged + lost,
    };
  }

  Future<void> loadDetail(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _service.getReturnReport(reportId);
      final invMap = <String, InventoryRow>{};

      if (_report != null) {
        for (final item in _report!.items) {
          try {
            final rows = await _service.getInventory(itemId: item.itemId);
            if (rows.isNotEmpty) {
              invMap[item.itemId] = rows.first;
            }
          } catch (_) {}
        }
      }

      _inventoryByItem = invMap;
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> confirmReturnReport(String reportId) async {
    _isConfirming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _service.confirmReturnReport(reportId);
      _isConfirming = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isConfirming = false;
      notifyListeners();
      return false;
    }
  }
}
