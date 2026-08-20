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
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Header & Controls matching mockup
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LỊCH TRÌNH',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLabel,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Tháng ${DateFormat('M, yyyy').format(_selectedDate)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.warmTextDark,
                          fontFamily: 'serif',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _goToToday,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A359),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'Hôm nay',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: < Full Date Navigator >
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.warmTextDark),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _previousWeek,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        Formatters.formatFullDate(selectedDateStr),
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmTextDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.warmTextDark),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _nextWeek,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Horizontal 7-Day Selector
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
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFD4A359) : const Color(0xFFFFF2E8),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD4A359).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  weekdayLabels[index],
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF8C7456),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  dayDate.day < 10 ? '0${dayDate.day}' : '${dayDate.day}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.warmTextDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasPlans
                                        ? (isSelected ? Colors.white : AppColors.goldPrimary)
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  if (dayPlans.isEmpty) ...[
                    const EmptyStateWidget(
                      message: 'Không có kế hoạch nào trong ngày này.',
                      icon: LucideIcons.calendarCheck,
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16, top: 4),
                      child: Text(
                        '${dayPlans.length} CÔNG VIỆC TRONG NGÀY',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8C7355),
                          letterSpacing: 1.2,
                        ),
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

                    // End of Day Footer Divider matching mockup
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFEFE8DC), height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'HẾT LỊCH TRÌNH NGÀY ${DateFormat('dd/MM').format(_selectedDate)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC4B5A5),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFEFE8DC), height: 1)),
                        ],
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
