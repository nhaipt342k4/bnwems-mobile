import 'package:flutter/material.dart';
import '../../data/models/manager_order.dart';
import '../../data/services/manager_order_service.dart';
import '../../../../core/utils/formatters.dart';

enum QuickFilter { all, today, upcoming, inProgress, completed }

class ManagerOrderListProvider extends ChangeNotifier {
  final ManagerOrderService _orderService;

  bool _isLoading = true;
  String? _errorMessage;

  List<ManagerOrder> _orders = [];
  String _search = '';
  String _orderStatus = '';
  String _paymentStatus = '';
  QuickFilter _quickFilter = QuickFilter.all;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  String get orderStatus => _orderStatus;
  String get paymentStatus => _paymentStatus;
  QuickFilter get quickFilter => _quickFilter;

  ManagerOrderListProvider({ManagerOrderService? orderService})
      : _orderService = orderService ?? ManagerOrderService();

  List<ManagerOrder> get filteredOrders {
    final todayIso = Formatters.toIsoDateOnly(DateTime.now());

    switch (_quickFilter) {
      case QuickFilter.today:
        return _orders.where((o) => o.eventDate.startsWith(todayIso)).toList();
      case QuickFilter.upcoming:
        return _orders
            .where((o) => o.eventDate.compareTo(todayIso) > 0 && o.orderStatus != 'CANCELLED')
            .toList();
      case QuickFilter.inProgress:
        return _orders.where((o) => o.orderStatus == 'IN_PROGRESS').toList();
      case QuickFilter.completed:
        return _orders.where((o) => o.orderStatus == 'COMPLETED').toList();
      case QuickFilter.all:
        return _orders;
    }
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.getOrders(
        limit: 100,
        search: _search.isNotEmpty ? _search : null,
        orderStatus: _orderStatus.isNotEmpty ? _orderStatus : null,
        paymentStatus: _paymentStatus.isNotEmpty ? _paymentStatus : null,
      );
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  void setSearch(String val) {
    _search = val;
    fetchOrders();
  }

  void setOrderStatus(String val) {
    _orderStatus = val;
    fetchOrders();
  }

  void setPaymentStatus(String val) {
    _paymentStatus = val;
    fetchOrders();
  }

  void setQuickFilter(QuickFilter filter) {
    _quickFilter = filter;
    notifyListeners();
  }
}
