import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    switch (status) {
      case 'IN_PROGRESS':
        return Colors.amber.shade50;
      case 'COMPLETED':
        return Colors.green.shade50;
      case 'CANCELLED':
        return Colors.red.shade50;
      case 'CONFIRMED':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return Colors.amber.shade800;
      case 'COMPLETED':
        return Colors.green.shade800;
      case 'CANCELLED':
        return Colors.red.shade800;
      case 'CONFIRMED':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerScheduleProvider>();
    final weekDays = provider.weekDays;
    final selectedIso = Formatters.toIsoDateOnly(provider.selectedDate);
    final dayPlans = provider.dayPlans;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Week Bar & Navigation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 20),
                          onPressed: () => provider.prevWeek(),
                        ),
                        Text(
                          'Tháng ${provider.selectedDate.month}/${provider.selectedDate.year}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, size: 20),
                          onPressed: () => provider.nextWeek(),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => provider.goToToday(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      child: const Text('Hôm nay', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 7 Days Pill Selector
                Row(
                  children: List.generate(7, (index) {
                    final day = weekDays[index];
                    final dayIso = Formatters.toIsoDateOnly(day);
                    final isSelected = dayIso == selectedIso;
                    final hasPlans = provider.datesWithPlans.contains(dayIso);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => provider.selectDate(day),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
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
                                day.day.toString(),
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

          // Day Timeline List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchSchedule(),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
                      : dayPlans.isEmpty
                          ? const Center(child: Text('Không có kế hoạch nào ngày này.', style: TextStyle(color: AppColors.textMuted)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: dayPlans.length,
                              itemBuilder: (context, index) {
                                final plan = dayPlans[index];
                                final isCancelled = plan.status == 'CANCELLED';

                                return InkWell(
                                  onTap: () {
                                    if (plan.orderId.isNotEmpty) {
                                      context.push('/manager/orders/${plan.orderId}');
                                    } else if (plan.planId.isNotEmpty) {
                                      context.push('/staff/tasks/${plan.planId}');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isCancelled ? Colors.white.withValues(alpha: 0.6) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.borderLight),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _getStatusBgColor(plan.status),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                Formatters.formatStatus(plan.status),
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusTextColor(plan.status)),
                                              ),
                                            ),
                                            Text(plan.planCode, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          plan.taskName ?? 'Kế hoạch',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${plan.eventName ?? plan.orderCode ?? ''} ${plan.customerName != null ? '— ${plan.customerName}' : ''}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.clock, size: 13, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${Formatters.formatTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      if (plan.location != null || plan.orderLocation != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.mapPin, size: 13, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                plan.location ?? plan.orderLocation!,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (plan.assignees != null && plan.assignees!.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: plan.assignees!.map((assignee) {
                                            final isLead = assignee.role == 'LEAD';
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isLead ? Colors.purple.shade50 : Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(LucideIcons.user, size: 11, color: isLead ? Colors.purple.shade700 : Colors.blue.shade700),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    assignee.fullName,
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLead ? Colors.purple.shade700 : Colors.blue.shade700),
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
                               );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
