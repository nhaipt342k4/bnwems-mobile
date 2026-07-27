import '../../data/models/deposit.dart';
import '../../data/models/manager_order.dart';

abstract class ManagerDepositState {}

class ManagerDepositInitial extends ManagerDepositState {}

class ManagerDepositLoading extends ManagerDepositState {}

class ManagerDepositLoaded extends ManagerDepositState {
  final ManagerOrder order;
  final Deposit? deposit;
  final String paymentMethod;
  final String notes;

  ManagerDepositLoaded({
    required this.order,
    this.deposit,
    this.paymentMethod = 'bank_transfer',
    this.notes = '',
  });
}

class ManagerDepositError extends ManagerDepositState {
  final String message;

  ManagerDepositError(this.message);
}
