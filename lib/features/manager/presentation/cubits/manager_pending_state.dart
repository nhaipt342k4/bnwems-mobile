import '../../data/models/pending_summary.dart';

abstract class ManagerPendingState {}

class ManagerPendingInitial extends ManagerPendingState {}

class ManagerPendingLoading extends ManagerPendingState {}

class ManagerPendingLoaded extends ManagerPendingState {
  final PendingSummary summary;
  final String activeCategory;

  ManagerPendingLoaded({
    required this.summary,
    this.activeCategory = 'all',
  });
}

class ManagerPendingError extends ManagerPendingState {
  final String message;

  ManagerPendingError(this.message);
}
