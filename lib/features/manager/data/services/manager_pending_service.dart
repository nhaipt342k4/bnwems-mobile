import '../models/pending_summary.dart';
import '../models/deposit.dart';
import '../models/settlement.dart';
import 'manager_order_service.dart';
import 'manager_deposit_service.dart';
import 'manager_settlement_service.dart';
import 'manager_change_request_service.dart';
import 'manager_inventory_service.dart';

class ManagerPendingService {
  final ManagerOrderService _orderService;
  final ManagerDepositService _depositService;
  final ManagerSettlementService _settlementService;
  final ManagerChangeRequestService _changeRequestService;
  final ManagerInventoryService _inventoryService;

  ManagerPendingService({
    ManagerOrderService? orderService,
    ManagerDepositService? depositService,
    ManagerSettlementService? settlementService,
    ManagerChangeRequestService? changeRequestService,
    ManagerInventoryService? inventoryService,
  })  : _orderService = orderService ?? ManagerOrderService(),
        _depositService = depositService ?? ManagerDepositService(),
        _settlementService = settlementService ?? ManagerSettlementService(),
        _changeRequestService = changeRequestService ?? ManagerChangeRequestService(),
        _inventoryService = inventoryService ?? ManagerInventoryService();

  /// Gộp mọi nội dung đang chờ Manager xử lý tương tự pendingApiService.ts trên FE Web
  Future<PendingSummary> getPendingSummary() async {
    try {
      final orders = await _orderService.getOrders(limit: 15);

      final depositCandidates = orders.where((order) => order.paymentStatus == 'UNPAID').take(10).toList();
      final settlementCandidates = orders.where((order) => order.orderStatus == 'IN_PROGRESS').take(10).toList();

      final results = await Future.wait([
        // Deposits
        Future.wait(depositCandidates.map((order) async {
          try {
            final deposits = await _depositService.getOrderDeposits(order.orderId);
            return deposits
                .where((d) => d.status == 'UNPAID')
                .map((d) => d.copyWithPendingInfo(
                      orderCode: order.orderCode,
                      customerName: order.customerName,
                      eventName: order.eventName,
                    ))
                .toList();
          } catch (_) {
            return <Deposit>[];
          }
        })),

        // Settlements
        Future.wait(settlementCandidates.map((order) async {
          try {
            final settlement = await _settlementService.getOrderSettlement(order.orderId);
            if (settlement != null && settlement.status == 'UNPAID') {
              return settlement.copyWithPendingInfo(
                orderCode: order.orderCode,
                customerName: order.customerName,
                eventName: order.eventName,
              );
            }
            return null;
          } catch (_) {
            return null;
          }
        })),

        // Change Requests
        _changeRequestService.getChangeRequests(status: 'pending'),

        // Return Reports
        _inventoryService.getReturnReports(status: 'SUBMITTED'),
      ]);

      final rawDeposits = results[0] as List<List<Deposit>>;
      final rawSettlements = results[1] as List<Settlement?>;
      final changeRequests = results[2] as List;
      final rawReports = results[3] as List;

      final deposits = rawDeposits.expand((x) => x).toList();
      final settlements = rawSettlements.whereType<Settlement>().toList();
      final returnReports = rawReports.where((r) => r.reportType == 'INTERNAL').toList();

      return PendingSummary(
        deposits: deposits,
        settlements: settlements,
        changeRequests: changeRequests.cast(),
        returnReports: returnReports.cast(),
      );
    } catch (e) {
      return PendingSummary.empty();
    }
  }
}
