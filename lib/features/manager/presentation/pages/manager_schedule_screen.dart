import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_schedule_provider.dart';

class ManagerScheduleScreen extends StatefulWidget {
  const ManagerScheduleScreen({super.key});

  @override
  State<ManagerScheduleScreen> createState() => _ManagerScheduleScreenState();
}

class _ManagerScheduleScreenState extends State<ManagerScheduleScreen> {
  static const weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerScheduleProvider>().fetchSchedule();
    });
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return const Color(0xFFFEF3C7);
      case 'COMPLETED':
        return const Color(0xFFDCFCE7);
      case 'CANCELLED':
        return const Color(0xFFFEE2E2);
      case 'CONFIRMED':
        return const Color(0xFFE0F2FE);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return const Color(0xFFD97706);
      case 'COMPLETED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      case 'CONFIRMED':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color ?? const Color(0xFF8C7B6B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? const Color(0xFF5C4E43),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerScheduleProvider>();
    final weekDays = provider.weekDays;
    final selectedIso = Formatters.toIsoDateOnly(provider.selectedDate);
    final dayPlans = provider.dayPlans;

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
                  // Category Tag + Row 1: Large Serif Month Header + Today Button
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
                        'Tháng ${DateFormat('M, yyyy').format(provider.selectedDate)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.warmTextDark,
                          fontFamily: 'serif',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.goToToday(),
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
                        onPressed: () => provider.prevWeek(),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        Formatters.formatFullDate(selectedIso),
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
                        onPressed: () => provider.nextWeek(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Horizontal 7-Day Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final day = weekDays[index];
                      final dayIso = Formatters.toIsoDateOnly(day);
                      final isSelected = dayIso == selectedIso;
                      final hasPlans = provider.datesWithPlans.contains(dayIso);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => provider.selectDate(day),
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
                                  day.day < 10 ? '0${day.day}' : '${day.day}',
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

            // Day Timeline List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.goldPrimary,
                onRefresh: () => provider.fetchSchedule(),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                    : provider.errorMessage != null
                        ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
                        : dayPlans.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: Text('Không có kế hoạch nào ngày này.', style: TextStyle(color: AppColors.warmTextMuted))),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: dayPlans.length + 1,
                                itemBuilder: (context, i) {
                                  if (i == 0) {
                                    return Padding(
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
                                    );
                                  }
                                  final index = i - 1;
                                  final plan = dayPlans[index];
                                  final isCancelled = plan.status == 'CANCELLED';
                                  final isCompleted = plan.status == 'COMPLETED';
                                  final dotColor = _getStatusTextColor(plan.status);
                                  final isFirst = index == 0;
                                  final isLast = index == dayPlans.length - 1;
                                  final loc = plan.location ?? plan.orderLocation;

                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Cột giờ
                                        SizedBox(
                                          width: 44,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 1),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  Formatters.formatTime(plan.startTime),
                                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                                                ),
                                                if (plan.endTime != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    Formatters.formatTime(plan.endTime),
                                                    style: const TextStyle(fontSize: 11, color: AppColors.warmTextMuted),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Rail: đường nối + chấm màu theo trạng thái
                                        SizedBox(
                                          width: 18,
                                          child: Column(
                                            children: [
                                              Container(width: 2, height: 3, color: isFirst ? Colors.transparent : const Color(0xFFEAD8B7)),
                                              Container(
                                                width: 15,
                                                height: 15,
                                                decoration: BoxDecoration(
                                                  color: dotColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2.5),
                                                  boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.25), blurRadius: 4, spreadRadius: 1)],
                                                ),
                                                child: isCompleted ? const Icon(LucideIcons.check, size: 8, color: Colors.white) : null,
                                              ),
                                              Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : const Color(0xFFEAD8B7))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Thẻ nội dung
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: InkWell(
                                              onTap: () {
                                                if (plan.planId.isNotEmpty) {
                                                  context.push('/manager/plans/${plan.planId}');
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: const Border(
                                                    top: BorderSide(color: AppColors.goldPrimary, width: 3),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.04),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Header: Task Name + Code (Left) + Status Badge (Right)
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                plan.taskName ?? 'Kế hoạch công việc',
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 17.5,
                                                                  fontWeight: FontWeight.w400,
                                                                  fontFamily: 'serif',
                                                                  color: isCancelled ? AppColors.warmTextMuted : AppColors.warmTextDark,
                                                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Text(
                                                                plan.planCode,
                                                                style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: _getStatusBgColor(plan.status),
                                                            borderRadius: BorderRadius.circular(14),
                                                          ),
                                                          child: Text(
                                                            Formatters.formatStatus(plan.status),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: _getStatusTextColor(plan.status),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 14),
                                                      child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                                                    ),

                                                    // Đơn hàng / sự kiện
                                                    _infoRow(
                                                      LucideIcons.calendar,
                                                      Formatters.formatOrderEvent(plan.orderCode, plan.eventName),
                                                      color: AppColors.goldPrimary,
                                                      bold: true,
                                                    ),
                                                    if (plan.customerName != null && plan.customerName!.isNotEmpty) ...[
                                                      const SizedBox(height: 10),
                                                      _infoRow(LucideIcons.building2, plan.customerName!),
                                                    ],
                                                    if (loc != null && loc.isNotEmpty) ...[
                                                      const SizedBox(height: 10),
                                                      _infoRow(LucideIcons.mapPin, loc),
                                                    ],

                                                    // Footer: nhân sự phụ trách
                                                    if (plan.assignees != null && plan.assignees!.isNotEmpty) ...[
                                                      const SizedBox(height: 14),
                                                      Container(height: 1, color: const Color(0xFFF0E8DC)),
                                                      const SizedBox(height: 10),
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: plan.assignees!.map((assignee) {
                                                          final isLead = assignee.role == 'LEAD';
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFF7F2EA),
                                                              borderRadius: BorderRadius.circular(16),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(isLead ? LucideIcons.userCheck : LucideIcons.user, size: 12, color: isLead ? const Color(0xFF7E22CE) : AppColors.goldLabel),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  assignee.fullName,
                                                                  style: TextStyle(
                                                                    fontSize: 11.5,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: isLead ? const Color(0xFF7E22CE) : AppColors.goldLabel,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
