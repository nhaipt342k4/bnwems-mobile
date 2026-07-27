import '../../data/models/pending_summary.dart';

abstract class ManagerDashboardState {}

class ManagerDashboardInitial extends ManagerDashboardState {}

class ManagerDashboardLoading extends ManagerDashboardState {}

class ManagerDashboardLoaded extends ManagerDashboardState {
  final Map<String, dynamic> stats;
  final List<dynamic> todaySchedule;
  final List<dynamic> upcomingOrders;
  final PendingSummary pendingSummary;

  ManagerDashboardLoaded({
    required this.stats,
    required this.todaySchedule,
    required this.upcomingOrders,
    required this.pendingSummary,
  });
}

class ManagerDashboardError extends ManagerDashboardState {
  final String message;

  ManagerDashboardError(this.message);
}
