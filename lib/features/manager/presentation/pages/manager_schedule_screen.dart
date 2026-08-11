import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // Suy icon + màu loại việc từ tên (manager model không có taskCode).
  ({Color bg, Color fg, IconData icon}) _typeFromName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('khảo sát')) return (bg: AppColors.surveyBg, fg: AppColors.surveyText, icon: LucideIcons.clipboardList);
    if (n.contains('lắp đặt')) return (bg: AppColors.setupBg, fg: AppColors.setupText, icon: LucideIcons.wrench);
    if (n.contains('thu hồi') || n.contains('hoàn kho')) return (bg: AppColors.collectBg, fg: AppColors.collectText, icon: LucideIcons.packageOpen);
    return (bg: AppColors.surveyBg, fg: AppColors.surveyText, icon: LucideIcons.calendarClock);
  }

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? AppColors.textSecondary,
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
                          ? ListView(
                              // giữ pull-to-refresh khi rỗng
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text('Không có kế hoạch nào ngày này.', style: TextStyle(color: AppColors.textMuted))),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: dayPlans.length + 1,
                              itemBuilder: (context, i) {
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 14, top: 2),
                                    child: Text(
                                      '${dayPlans.length} công việc trong ngày',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                    ),
                                  );
                                }
                                final index = i - 1;
                                final plan = dayPlans[index];
                                final isCancelled = plan.status == 'CANCELLED';
                                final isCompleted = plan.status == 'COMPLETED';
                                final dotColor = _getStatusTextColor(plan.status);
                                final ty = _typeFromName(plan.taskName);
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
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                              ),
                                              if (plan.endTime != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  Formatters.formatTime(plan.endTime),
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                                            Container(width: 2, height: 3, color: isFirst ? Colors.transparent : AppColors.border),
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
                                            Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : AppColors.border)),
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
                                            borderRadius: BorderRadius.circular(14),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isCancelled ? Colors.white.withValues(alpha: 0.6) : AppColors.surface,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: AppColors.borderLight),
                                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                                              ),
                                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Header: icon loại việc + tên/mã + trạng thái
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration: BoxDecoration(color: ty.bg, borderRadius: BorderRadius.circular(10)),
                                                        child: Icon(ty.icon, size: 18, color: ty.fg),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              plan.taskName ?? 'Kế hoạch',
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 14.5,
                                                                fontWeight: FontWeight.bold,
                                                                height: 1.15,
                                                                color: isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              plan.planCode,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                        decoration: BoxDecoration(color: _getStatusBgColor(plan.status), borderRadius: BorderRadius.circular(999)),
                                                        child: Text(
                                                          Formatters.formatStatus(plan.status),
                                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusTextColor(plan.status)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),

                                                  // Đơn hàng / sự kiện
                                                  _infoRow(
                                                    LucideIcons.hash,
                                                    '${plan.orderCode ?? ''}${plan.eventName != null && plan.eventName!.isNotEmpty ? ' · ${plan.eventName}' : ''}',
                                                    color: AppColors.primary,
                                                    bold: true,
                                                  ),
                                                  if (plan.customerName != null && plan.customerName!.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    _infoRow(LucideIcons.user, plan.customerName!),
                                                  ],
                                                  if (loc != null && loc.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    _infoRow(LucideIcons.mapPin, loc),
                                                  ],

                                                  // Footer: nhân sự phụ trách (thay cho check-in của staff)
                                                  if (plan.assignees != null && plan.assignees!.isNotEmpty) ...[
                                                    const SizedBox(height: 12),
                                                    Container(height: 1, color: AppColors.borderLight),
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: plan.assignees!.map((assignee) {
                                                        final isLead = assignee.role == 'LEAD';
                                                        return Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: isLead ? AppColors.leaderPurpleBg : Colors.blue.shade50,
                                                            borderRadius: BorderRadius.circular(999),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(isLead ? LucideIcons.userCheck : LucideIcons.user, size: 11, color: isLead ? AppColors.leaderPurple : Colors.blue.shade700),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                assignee.fullName,
                                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLead ? AppColors.leaderPurple : Colors.blue.shade700),
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
    );
  }
}
