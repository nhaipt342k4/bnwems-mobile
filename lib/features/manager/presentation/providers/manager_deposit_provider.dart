import 'package:flutter/material.dart';
import '../../data/models/manager_order.dart';
import '../../data/models/deposit.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_deposit_service.dart';

class ManagerDepositProvider extends ChangeNotifier {
  final ManagerOrderService _orderService;
  final ManagerDepositService _depositService;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isConfirming = false;
  String? _errorMessage;
  String? _formError;

  ManagerOrder? _order;
  List<Deposit> _deposits = [];

  String _amount = '';
  String _dueDate = '';
  String _paymentMethod = 'bank_transfer';
  String _notes = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isConfirming => _isConfirming;
  String? get errorMessage => _errorMessage;
  String? get formError => _formError;

  ManagerOrder? get order => _order;
  List<Deposit> get deposits => _deposits;

  String get amount => _amount;
  String get dueDate => _dueDate;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;

  ManagerDepositProvider({
    ManagerOrderService? orderService,
    ManagerDepositService? depositService,
  })  : _orderService = orderService ?? ManagerOrderService(),
        _depositService = depositService ?? ManagerDepositService();

  static String normalizePaymentMethod(String? raw) {
    if (raw == null || raw.isEmpty) return 'bank_transfer';
    final lower = raw.toLowerCase();
    if (lower.contains('tiền mặt') || lower.contains('cash')) {
      return 'cash';
    }
    return 'bank_transfer';
  }

  double get depositCollected =>
      _deposits.where((d) => d.status == 'PAID').fold(0.0, (sum, d) => sum + d.amount);

  Deposit? get currentDeposit =>
      _deposits.firstWhere((d) => d.status == 'UNPAID', orElse: () => _deposits.isNotEmpty ? _deposits.first : Deposit(
        depositId: '',
        depositCode: '',
        orderId: '',
        amount: 0,
        status: 'UNPAID',
        createdAt: '',
        updatedAt: '',
      ));

  bool get isPaid => currentDeposit?.status == 'PAID';

  double get displayAmount {
    final numVal = double.tryParse(_amount);
    if (numVal != null && numVal > 0) return numVal;
    if (currentDeposit != null && currentDeposit!.amount > 0) return currentDeposit!.amount;
    return _order != null ? (_order!.totalAmount * 0.3).roundToDouble() : 0;
  }

  void setAmount(String val) {
    _amount = val;
    notifyListeners();
  }

  void setDueDate(String val) {
    _dueDate = val;
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

  Future<void> loadDepositData(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _orderService.getOrder(orderId),
        _depositService.getOrderDeposits(orderId),
      ]);

      _order = results[0] as ManagerOrder;
      _deposits = results[1] as List<Deposit>;

      final unpaid = _deposits.where((d) => d.status == 'UNPAID').toList();
      final active = unpaid.isNotEmpty ? unpaid.first : (_deposits.isNotEmpty ? _deposits.first : null);

      if (active != null) {
        _amount = active.amount.toInt().toString();
        _dueDate = active.dueDate != null && active.dueDate!.length >= 10 ? active.dueDate!.substring(0, 10) : '';
        _paymentMethod = normalizePaymentMethod(active.paymentMethod);
        _notes = active.notes ?? '';
      } else if (_order != null) {
        _amount = (_order!.totalAmount * 0.3).round().toString();
      }

      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> saveDeposit(String orderId) async {
    final numVal = double.tryParse(_amount);
    if (numVal == null || numVal <= 0) {
      _formError = 'Vui lòng nhập số tiền cọc hợp lệ.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _formError = null;
    notifyListeners();

    try {
      await _depositService.createOrderDeposit(
        orderId,
        amount: numVal,
        paymentMethod: _paymentMethod,
        notes: _notes.isNotEmpty ? _notes : null,
        dueDate: _dueDate.isNotEmpty ? DateTime.parse(_dueDate).toIso8601String() : null,
      );
      _isSaving = false;
      await loadDepositData(orderId);
      return true;
    } catch (e) {
      _formError = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPaid(String orderId) async {
    final dep = currentDeposit;
    if (dep == null || dep.depositId.isEmpty) {
      _formError = 'Chưa có thông tin cọc để xác nhận.';
      notifyListeners();
      return false;
    }

    _isConfirming = true;
    _formError = null;
    notifyListeners();

    try {
      await _depositService.updateDepositStatus(dep.depositId, status: 'PAID');
      _isConfirming = false;
      await loadDepositData(orderId);
      return true;
    } catch (e) {
      _formError = e.toString().replaceAll('Exception: ', '');
      _isConfirming = false;
      notifyListeners();
      return false;
    }
  }
}
