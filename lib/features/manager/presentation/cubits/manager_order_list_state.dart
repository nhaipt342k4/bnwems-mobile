import '../../data/models/manager_order.dart';

abstract class ManagerOrderListState {}

class ManagerOrderListInitial extends ManagerOrderListState {}

class ManagerOrderListLoading extends ManagerOrderListState {}

class ManagerOrderListLoaded extends ManagerOrderListState {
  final List<ManagerOrder> orders;
  final String? orderStatus;
  final String? paymentStatus;
  final String searchQuery;

  ManagerOrderListLoaded({
    required this.orders,
    this.orderStatus,
    this.paymentStatus,
    this.searchQuery = '',
  });
}

class ManagerOrderListError extends ManagerOrderListState {
  final String message;

  ManagerOrderListError(this.message);
}
