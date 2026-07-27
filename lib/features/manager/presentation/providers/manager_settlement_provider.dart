import 'package:flutter/material.dart';
import '../../data/models/manager_order.dart';
import '../../data/models/settlement.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_settlement_service.dart';
import '../../data/services/manager_deposit_service.dart';

class ManagerSettlementProvider extends ChangeNotifier {
  final ManagerOrderService _orderService;
  final ManagerSettlementService _settlementService;
  final ManagerDepositService _depositService;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isConfirming = false;
  String? _errorMessage;
  String? _formError;

  ManagerOrder? _order;
  Settlement? _settlement;
  double _depositCollected = 0.0;

  String _additionalFee = '0';
  String _compensation = '0';
  String _discount = '0';
  String _paymentMethod = 'bank_transfer';
  String _notes = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isConfirming => _isConfirming;
  String? get errorMessage => _errorMessage;
  String? get formError => _formError;

  ManagerOrder? get order => _order;
  Settlement? get settlement => _settlement;
  double get depositCollected => _depositCollected;

  String get additionalFee => _additionalFee;
  String get compensation => _compensation;
  String get discount => _discount;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;

  bool get isConfirmed => _settlement?.status == 'PAID';

  static String normalizePaymentMethod(String? raw) {
    if (raw == null || raw.isEmpty) return 'bank_transfer';
    final lower = raw.toLowerCase();
    if (lower.contains('tiền mặt') || lower.contains('cash')) {
      return 'cash';
    }
    return 'bank_transfer';
  }

  double get estimatedFinal {
    if (_order == null) return 0.0;
    final total = _order!.totalAmount;
    final addFee = double.tryParse(_additionalFee) ?? 0.0;
    final comp = double.tryParse(_compensation) ?? 0.0;
    final disc = double.tryParse(_discount) ?? 0.0;
    final result = total + addFee + comp - _depositCollected - disc;
    return result < 0 ? 0.0 : result;
  }

  double get finalAmountToDisplay {
    if (isConfirmed && _settlement != null) {
      return _settlement!.finalAmount;
    }
    return estimatedFinal;
  }

  ManagerSettlementProvider({
    ManagerOrderService? orderService,
    ManagerSettlementService? settlementService,
    ManagerDepositService? depositService,
  })  : _orderService = orderService ?? ManagerOrderService(),
        _settlementService = settlementService ?? ManagerSettlementService(),
        _depositService = depositService ?? ManagerDepositService();

  void setAdditionalFee(String val) {
    _additionalFee = val;
    notifyListeners();
  }

  void setCompensation(String val) {
    _compensation = val;
    notifyListeners();
  }

  void setDiscount(String val) {
    _discount = val;
    notifyListeners();
  }

  void setPaymentMethod(String val) {
    _paymentMethod = normalizePaymentMethod(val);
    notifyListeners();
  }

  void setNotes(String val) {
    _notes = val;
    notifyListeners();
  }

  Future<void> loadSettlementData(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _orderService.getOrder(orderId),
        _settlementService.getOrderSettlement(orderId),
        _depositService.getOrderDeposits(orderId),
      ]);

      _order = results[0] as ManagerOrder;
      _settlement = results[1] as Settlement?;
      final deposits = results[2] as List;

      _depositCollected = deposits
          .where((d) => d.status == 'PAID')
          .fold(0.0, (sum, d) => sum + (d.amount as double));

      if (_settlement != null) {
        _additionalFee = _settlement!.additionalFee.toInt().toString();
        _compensation = _settlement!.compensation.toInt().toString();
        _discount = _settlement!.discount.toInt().toString();
        _paymentMethod = normalizePaymentMethod(_settlement!.paymentMethod);
        _notes = _settlement!.notes ?? '';
      }

      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> saveSettlement(String orderId) async {
    _isSaving = true;
    _formError = null;
    notifyListeners();

    try {
      _settlement = await _settlementService.recordSettlement(
        orderId,
        additionalFee: double.tryParse(_additionalFee) ?? 0.0,
        compensation: double.tryParse(_compensation) ?? 0.0,
        discount: double.tryParse(_discount) ?? 0.0,
        paymentMethod: _paymentMethod,
        notes: _notes.isNotEmpty ? _notes : null,
      );
      _isSaving = false;
      await loadSettlementData(orderId);
      return true;
    } catch (e) {
      _formError = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmSettlement(String orderId) async {
    if (_settlement == null || _settlement!.settlementId.isEmpty) {
      _formError = 'Chưa có hồ sơ quyết toán để xác nhận.';
      notifyListeners();
      return false;
    }

    _isConfirming = true;
    _formError = null;
    notifyListeners();

    try {
      await _settlementService.confirmSettlement(_settlement!.settlementId, status: 'PAID');
      await _orderService.updateOrderStatus(orderId, orderStatus: 'COMPLETED');
      _isConfirming = false;
      await loadSettlementData(orderId);
      return true;
    } catch (e) {
      _formError = e.toString().replaceAll('Exception: ', '');
      _isConfirming = false;
      notifyListeners();
      return false;
    }
  }
}
