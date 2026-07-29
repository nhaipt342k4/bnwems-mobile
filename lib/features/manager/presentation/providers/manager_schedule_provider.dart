import 'package:flutter/material.dart';
import '../../data/models/manager_schedule_plan.dart';
import '../../data/services/manager_schedule_service.dart';
import '../../../../core/utils/formatters.dart';

class ManagerScheduleProvider extends ChangeNotifier {
  final ManagerScheduleService _service;

  bool _isLoading = true;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now();
  List<ManagerSchedulePlan> _plans = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  DateTime get weekStart => _weekStart;
  List<ManagerSchedulePlan> get plans => _plans;

  ManagerScheduleProvider({ManagerScheduleService? service})
      : _service = service ?? ManagerScheduleService() {
    _weekStart = _getMonday(DateTime.now());
  }

  DateTime _getMonday(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get weekDays {
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  Set<String> get datesWithPlans {
    final set = <String>{};
    for (final plan in _plans) {
      if (plan.startTime.length >= 10) {
        set.add(plan.startTime.substring(0, 10));
      }
    }
    return set;
  }

  List<ManagerSchedulePlan> get dayPlans {
    final selIso = Formatters.toIsoDateOnly(_selectedDate);
    return _plans
        .where((p) => p.startTime.startsWith(selIso))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void prevWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    fetchSchedule();
  }

  void nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _selectedDate = _selectedDate.add(const Duration(days: 7));
    fetchSchedule();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    _weekStart = _getMonday(DateTime.now());
    fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _service.getSchedulePlans(limit: 500);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }
}
