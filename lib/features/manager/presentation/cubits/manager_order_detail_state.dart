import '../../data/models/manager_order.dart';

abstract class ManagerOrderDetailState {}

class ManagerOrderDetailInitial extends ManagerOrderDetailState {}

class ManagerOrderDetailLoading extends ManagerOrderDetailState {}

class ManagerOrderDetailLoaded extends ManagerOrderDetailState {
  final ManagerOrder order;
  final List<dynamic> schedulePlans;

  ManagerOrderDetailLoaded({
    required this.order,
    this.schedulePlans = const [],
  });
}

class ManagerOrderDetailError extends ManagerOrderDetailState {
  final String message;

  ManagerOrderDetailError(this.message);
}
