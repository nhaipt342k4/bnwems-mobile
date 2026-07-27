import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/manager_order.dart';
import '../../data/services/manager_order_service.dart';
import '../../data/services/manager_schedule_service.dart';
import 'manager_order_detail_state.dart';

class ManagerOrderDetailCubit extends Cubit<ManagerOrderDetailState> {
  final ManagerOrderService _orderService;
  final ManagerScheduleService _scheduleService;

  ManagerOrderDetailCubit({
    ManagerOrderService? orderService,
    ManagerScheduleService? scheduleService,
  })  : _orderService = orderService ?? ManagerOrderService(),
        _scheduleService = scheduleService ?? ManagerScheduleService(),
        super(ManagerOrderDetailInitial());

  Future<void> loadOrderDetail(String orderId) async {
    emit(ManagerOrderDetailLoading());

    try {
      final results = await Future.wait([
        _orderService.getOrder(orderId),
        _scheduleService.getSchedulePlans(orderId: orderId),
      ]);

      final order = results[0] as ManagerOrder;
      final schedulePlans = results[1] as List<dynamic>;

      emit(ManagerOrderDetailLoaded(
        order: order,
        schedulePlans: schedulePlans,
      ));
    } catch (e) {
      emit(ManagerOrderDetailError(e.toString()));
    }
  }

  Future<bool> cancelOrder(String orderId, String cancelReason, String? notes) async {
    try {
      await _orderService.updateOrderStatus(
        orderId,
        orderStatus: 'CANCELLED',
        cancelReason: cancelReason,
        notes: notes,
      );
      await loadOrderDetail(orderId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
