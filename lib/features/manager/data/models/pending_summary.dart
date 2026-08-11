import 'deposit.dart';
import 'settlement.dart';
import 'change_request.dart';
import 'collected_equipment_report.dart';
import 'survey_pending.dart';

class PendingSummary {
  final List<Deposit> deposits;
  final List<Settlement> settlements;
  final List<ChangeRequest> changeRequests;
  final List<CollectedEquipmentReport> returnReports;
  final List<SurveyPending> surveys;

  PendingSummary({
    required this.deposits,
    required this.settlements,
    required this.changeRequests,
    required this.returnReports,
    this.surveys = const [],
  });

  factory PendingSummary.empty() {
    return PendingSummary(
      deposits: [],
      settlements: [],
      changeRequests: [],
      returnReports: [],
      surveys: [],
    );
  }

  int get totalCount => deposits.length + settlements.length + changeRequests.length + returnReports.length + surveys.length;
}
