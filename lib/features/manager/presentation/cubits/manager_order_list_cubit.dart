import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/manager_order.dart';
import '../../data/services/manager_order_service.dart';
import 'manager_order_list_state.dart';

class ManagerOrderListCubit extends Cubit<ManagerOrderListState> {
  final ManagerOrderService _orderService;

  String? _orderStatus;
  String? _paymentStatus;
  String _searchQuery = '';

  ManagerOrderListCubit({ManagerOrderService? orderService})
      : _orderService = orderService ?? ManagerOrderService(),
        super(ManagerOrderListInitial());

  Future<void> loadOrders({
    String? orderStatus,
    String? paymentStatus,
    String? search,
  }) async {
    if (orderStatus != null) _orderStatus = orderStatus == 'ALL' ? null : orderStatus;
    if (paymentStatus != null) _paymentStatus = paymentStatus == 'ALL' ? null : paymentStatus;
    if (search != null) _searchQuery = search;

    emit(ManagerOrderListLoading());

    try {
      final orders = await _orderService.getOrders(
        orderStatus: _orderStatus,
        paymentStatus: _paymentStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      emit(ManagerOrderListLoaded(
        orders: orders,
        orderStatus: _orderStatus,
        paymentStatus: _paymentStatus,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      emit(ManagerOrderListError(e.toString()));
    }
  }

  void setFilter({String? orderStatus, String? paymentStatus}) {
    loadOrders(orderStatus: orderStatus, paymentStatus: paymentStatus);
  }

  void setSearchQuery(String query) {
    loadOrders(search: query);
  }
}
