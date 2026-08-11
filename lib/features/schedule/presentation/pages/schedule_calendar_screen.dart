import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/data/services/evidence_api_service.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../tasks/presentation/widgets/check_in_modal_bottom_sheet.dart';
import '../widgets/schedule_timeline_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ScheduleCalendarScreen extends StatefulWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStartDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _weekStartDate = _getMonday(_selectedDate);
  }

  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Mon .. 7 = Sun
    return date.subtract(Duration(days: weekday - 1));
  }

  List<DateTime> get _currentWeekDays {
    return List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));
  }

  void _previousWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
      _selectedDate = _weekStartDate;
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.add(const Duration(days: 7));
      _selectedDate = _weekStartDate;
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _weekStartDate = _getMonday(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final taskProvider = context.watch<TaskProvider>();
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final monthYearStr = 'Tháng ${DateFormat('M, yyyy').format(_selectedDate)}';

    final datesWithPlans = taskProvider.myPlans.map((p) {
      try {
        final localDate = Formatters.parseVietnamDateTime(p.startTime);
        return Formatters.toIsoDateOnly(localDate);
      } catch (_) {
        return p.startTime.split('T').first;
      }
    }).toSet();

    final dayPlans = taskProvider.myPlans.where((p) {
      try {
        final localDate = Formatters.parseVietnamDateTime(p.startTime);
        return Formatters.toIsoDateOnly(localDate) == selectedDateStr;
      } catch (_) {
        return p.startTime.startsWith(selectedDateStr);
      }
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Header & Controls
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthYearStr.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _previousWeek,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Formatters.formatFullDate(selectedDateStr),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(LucideIcons.chevronRight, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _nextWeek,
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _goToToday,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Hôm nay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal 7-Day Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayDate = _currentWeekDays[index];
                      final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);
                      final isSelected = DateUtils.isSameDay(dayDate, _selectedDate);
                      final hasPlans = datesWithPlans.contains(dayStr);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDate = dayDate),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.borderLight,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  weekdayLabels[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white70 : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dayDate.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasPlans
                                        ? (isSelected ? Colors.white : AppColors.primary)
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Timeline List of Selected Date
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (dayPlans.isEmpty) ...[
                    const EmptyStateWidget(
                      message: 'Không có kế hoạch nào trong ngày này.',
                      icon: LucideIcons.calendarCheck,
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 14),
                      child: Text(
                        '${dayPlans.length} công việc trong ngày',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ),
                    ...dayPlans.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final plan = entry.value;
                        final myAssignee = user != null ? taskProvider.getMyAssignee(plan, user.id) : null;
                        final activePlan = user != null ? taskProvider.getActiveCheckedInPlan(user.id) : null;
                        return ScheduleTimelineTile(
                          plan: plan,
                          myAssignee: myAssignee,
                          activePlan: activePlan,
                          isFirst: index == 0,
                          isLast: index == dayPlans.length - 1,
                          onCheckInPressed: () {
                            if (user != null) {
                              final activePlan = taskProvider.getActiveCheckedInPlan(user.id);
                              if (activePlan != null && activePlan.planId != plan.planId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Bạn đang thực hiện công việc "${activePlan.taskName}" (${activePlan.planCode}) chưa check-out. Vui lòng check-out trước khi check-in công việc mới.'),
                                    backgroundColor: Colors.red.shade700,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }
                              CheckInModalBottomSheet.show(
                                context,
                                taskName: plan.taskName,
                                locationName: plan.location,
                                targetLatitude: plan.latitude,
                                targetLongitude: plan.longitude,
                                onConfirmCheckIn: (photoFile, lat, lng) async {
                                  String? evidenceId;
                                  try {
                                    final ev = await EvidenceApiService().upload(photoFile);
                                    evidenceId = ev.evidenceId;
                                  } catch (_) {}
                                  await taskProvider.checkIn(
                                    plan.planId,
                                    user.id,
                                    checkInEvidenceId: evidenceId,
                                    latitude: lat,
                                    longitude: lng,
                                  );
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
