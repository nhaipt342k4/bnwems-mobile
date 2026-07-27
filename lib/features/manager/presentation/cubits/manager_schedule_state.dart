import '../../data/models/manager_schedule_plan.dart';

abstract class ManagerScheduleState {}

class ManagerScheduleInitial extends ManagerScheduleState {}

class ManagerScheduleLoading extends ManagerScheduleState {}

class ManagerScheduleLoaded extends ManagerScheduleState {
  final List<ManagerSchedulePlan> schedulePlans;
  final DateTime selectedDate;

  ManagerScheduleLoaded({
    required this.schedulePlans,
    required this.selectedDate,
  });
}

class ManagerScheduleError extends ManagerScheduleState {
  final String message;

  ManagerScheduleError(this.message);
}
