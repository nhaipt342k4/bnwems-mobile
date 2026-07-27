import 'deposit.dart';
import 'settlement.dart';
import 'change_request.dart';
import 'collected_equipment_report.dart';

class PendingSummary {
  final List<Deposit> deposits;
  final List<Settlement> settlements;
  final List<ChangeRequest> changeRequests;
  final List<CollectedEquipmentReport> returnReports;

  PendingSummary({
    required this.deposits,
    required this.settlements,
    required this.changeRequests,
    required this.returnReports,
  });

  factory PendingSummary.empty() {
    return PendingSummary(
      deposits: [],
      settlements: [],
      changeRequests: [],
      returnReports: [],
    );
  }

  int get totalCount => deposits.length + settlements.length + changeRequests.length + returnReports.length;
}
