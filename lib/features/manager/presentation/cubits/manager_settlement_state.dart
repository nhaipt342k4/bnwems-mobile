import '../../data/models/manager_order.dart';
import '../../data/models/settlement.dart';

abstract class ManagerSettlementState {}

class ManagerSettlementInitial extends ManagerSettlementState {}

class ManagerSettlementLoading extends ManagerSettlementState {}

class ManagerSettlementLoaded extends ManagerSettlementState {
  final ManagerOrder order;
  final Settlement? settlement;
  final String paymentMethod;

  ManagerSettlementLoaded({
    required this.order,
    this.settlement,
    this.paymentMethod = 'bank_transfer',
  });
}

class ManagerSettlementError extends ManagerSettlementState {
  final String message;

  ManagerSettlementError(this.message);
}
