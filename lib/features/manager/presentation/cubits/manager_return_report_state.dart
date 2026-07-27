import '../../data/models/collected_equipment_report.dart';

abstract class ManagerReturnReportState {}

class ManagerReturnReportInitial extends ManagerReturnReportState {}

class ManagerReturnReportLoading extends ManagerReturnReportState {}

class ManagerReturnReportListLoaded extends ManagerReturnReportState {
  final List<CollectedEquipmentReport> reports;

  ManagerReturnReportListLoaded(this.reports);
}

class ManagerReturnReportDetailLoaded extends ManagerReturnReportState {
  final CollectedEquipmentReport report;

  ManagerReturnReportDetailLoaded(this.report);
}

class ManagerReturnReportError extends ManagerReturnReportState {
  final String message;

  ManagerReturnReportError(this.message);
}
