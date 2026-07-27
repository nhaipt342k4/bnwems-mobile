import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/manager_pending_service.dart';
import 'manager_pending_state.dart';

class ManagerPendingCubit extends Cubit<ManagerPendingState> {
  final ManagerPendingService _pendingService;

  String _activeCategory = 'all';

  ManagerPendingCubit({ManagerPendingService? pendingService})
      : _pendingService = pendingService ?? ManagerPendingService(),
        super(ManagerPendingInitial());

  Future<void> loadPendingSummary({String? category}) async {
    if (category != null) _activeCategory = category;
    emit(ManagerPendingLoading());

    try {
      final summary = await _pendingService.getPendingSummary();
      emit(ManagerPendingLoaded(
        summary: summary,
        activeCategory: _activeCategory,
      ));
    } catch (e) {
      emit(ManagerPendingError(e.toString()));
    }
  }

  void setCategory(String category) {
    _activeCategory = category;
    if (state is ManagerPendingLoaded) {
      final current = state as ManagerPendingLoaded;
      emit(ManagerPendingLoaded(
        summary: current.summary,
        activeCategory: _activeCategory,
      ));
    }
  }
}
