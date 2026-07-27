import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/services/manager_schedule_service.dart';
import 'manager_schedule_state.dart';

class ManagerScheduleCubit extends Cubit<ManagerScheduleState> {
  final ManagerScheduleService _scheduleService;

  DateTime _selectedDate = DateTime.now();

  ManagerScheduleCubit({ManagerScheduleService? scheduleService})
      : _scheduleService = scheduleService ?? ManagerScheduleService(),
        super(ManagerScheduleInitial());

  Future<void> loadSchedule({DateTime? date}) async {
    if (date != null) _selectedDate = date;
    emit(ManagerScheduleLoading());

    try {
      final dateStr = Formatters.toIsoDateOnly(_selectedDate);
      final plans = await _scheduleService.getSchedulePlans(date: dateStr);
      emit(ManagerScheduleLoaded(
        schedulePlans: plans,
        selectedDate: _selectedDate,
      ));
    } catch (e) {
      emit(ManagerScheduleError(e.toString()));
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    loadSchedule(date: date);
  }
}
