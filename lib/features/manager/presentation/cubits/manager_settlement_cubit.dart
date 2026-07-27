import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/settlement.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_settlement_service.dart';
import 'manager_settlement_state.dart';

class ManagerSettlementCubit extends Cubit<ManagerSettlementState> {
  final ManagerSettlementService _settlementService;
  final ManagerOrderService _orderService;

  ManagerSettlementCubit({
    ManagerSettlementService? settlementService,
    ManagerOrderService? orderService,
  })  : _settlementService = settlementService ?? ManagerSettlementService(),
        _orderService = orderService ?? ManagerOrderService(),
        super(ManagerSettlementInitial());

  Future<void> loadSettlement(String orderId) async {
    emit(ManagerSettlementLoading());

    try {
      final order = await _orderService.getOrder(orderId);
      Settlement? settlement;
      try {
        settlement = await _settlementService.getOrderSettlement(orderId);
      } catch (_) {}

      emit(ManagerSettlementLoaded(
        order: order,
        settlement: settlement,
        paymentMethod: settlement?.paymentMethod == 'cash' ? 'cash' : 'bank_transfer',
      ));
    } catch (e) {
      emit(ManagerSettlementError(e.toString()));
    }
  }

  Future<bool> saveSettlement({
    required String orderId,
    required double additionalCost,
    required double damageCost,
    required double discount,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      await _settlementService.recordSettlement(
        orderId,
        additionalFee: additionalCost,
        compensation: damageCost,
        discount: discount,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await loadSettlement(orderId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmSettlement(String settlementId, String orderId) async {
    try {
      await _settlementService.confirmSettlement(settlementId, status: 'CONFIRMED');
      await loadSettlement(orderId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
