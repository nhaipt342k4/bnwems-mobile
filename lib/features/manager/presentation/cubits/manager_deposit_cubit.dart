import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/deposit.dart';
import '../../data/services/manager_deposit_service.dart';
import '../../data/services/manager_order_service.dart';
import 'manager_deposit_state.dart';

class ManagerDepositCubit extends Cubit<ManagerDepositState> {
  final ManagerDepositService _depositService;
  final ManagerOrderService _orderService;

  ManagerDepositCubit({
    ManagerDepositService? depositService,
    ManagerOrderService? orderService,
  })  : _depositService = depositService ?? ManagerDepositService(),
        _orderService = orderService ?? ManagerOrderService(),
        super(ManagerDepositInitial());

  Future<void> loadDeposit(String orderId) async {
    emit(ManagerDepositLoading());

    try {
      final order = await _orderService.getOrder(orderId);
      Deposit? deposit;
      try {
        final list = await _depositService.getOrderDeposits(orderId);
        if (list.isNotEmpty) deposit = list.first;
      } catch (_) {}

      emit(ManagerDepositLoaded(
        order: order,
        deposit: deposit,
        paymentMethod: deposit?.paymentMethod == 'cash' ? 'cash' : 'bank_transfer',
        notes: deposit?.notes ?? 'Đặt cọc theo chính sách Đặt cọc 30% giá trị đơn hàng.',
      ));
    } catch (e) {
      emit(ManagerDepositError(e.toString()));
    }
  }

  Future<bool> createDeposit({
    required String orderId,
    required double depositAmount,
    required String dueDate,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      await _depositService.createOrderDeposit(
        orderId,
        amount: depositAmount,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await loadDeposit(orderId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
