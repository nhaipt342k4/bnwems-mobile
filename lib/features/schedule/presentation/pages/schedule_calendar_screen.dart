import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

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
    final taskProvider = context.watch<TaskProvider>();
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final monthYearStr = 'Tháng ${DateFormat('M, yyyy').format(_selectedDate)}';

    final datesWithPlans = taskProvider.myPlans
        .map((p) => p.startTime.split('T').first)
        .toSet();

    final dayPlans = taskProvider.myPlans
        .where((p) => p.startTime.startsWith(selectedDateStr))
        .toList()
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
                    ...dayPlans.map(
                      (plan) => InkWell(
                        onTap: () => context.push('/staff/tasks/${plan.planId}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatTime(plan.startTime),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  AppBadge(
                                    label: Formatters.formatStatus(plan.status),
                                    backgroundColor: AppColors.primaryLight,
                                    textColor: AppColors.primaryDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                plan.taskName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${plan.orderCode} · ${plan.customerName}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              if (plan.location != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        plan.location!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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
