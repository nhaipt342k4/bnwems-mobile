import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final taskProvider = context.watch<TaskProvider>();

    final timeline = taskProvider.myPlans
        .map((plan) {
          final assignee = user != null ? taskProvider.getMyAssignee(plan, user.id) : null;
          if (assignee == null) return null;
          return {'plan': plan, 'assignee': assignee};
        })
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => (a['plan'].startTime as String).compareTo(b['plan'].startTime as String));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const AppHeader(
              title: 'Chấm công',
              subtitle: 'Trạng thái điểm danh theo từng kế hoạch',
            ),
            const SizedBox(height: 12),

            if (timeline.isEmpty) ...[
              const EmptyStateWidget(
                message: 'Chưa có lịch trình chấm công nào.',
                icon: LucideIcons.clock,
              ),
            ] else ...[
              Stack(
                children: [
                  Positioned(
                    left: 9,
                    top: 10,
                    bottom: 10,
                    child: Container(width: 2, color: AppColors.border),
                  ),
                  Column(
                    children: timeline.map((entry) {
                      final plan = entry['plan'];
                      final assignee = entry['assignee'];
                      final isCheckedIn = assignee.isCheckedIn;
                      final isCheckedOut = assignee.isCheckedOut;

                      String statusLabel = 'Chưa điểm danh';
                      Color statusBg = AppColors.pendingBg;
                      Color statusFg = AppColors.pendingText;

                      if (isCheckedOut) {
                        statusLabel = 'Đã check-out';
                        statusBg = AppColors.completedBg;
                        statusFg = AppColors.completedText;
                      } else if (isCheckedIn) {
                        statusLabel = 'Đang làm việc';
                        statusBg = AppColors.inProgressBg;
                        statusFg = AppColors.inProgressText;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0, left: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.taskName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  AppBadge(
                                    label: statusLabel,
                                    backgroundColor: statusBg,
                                    textColor: statusFg,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Formatters.formatDate(plan.startTime)} · ${Formatters.formatTime(plan.startTime)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Check-in: ${isCheckedIn ? Formatters.formatDateTime(assignee.checkInAt) : '--'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCheckedIn ? AppColors.completedText : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check-out: ${isCheckedOut ? Formatters.formatDateTime(assignee.checkOutAt) : '--'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCheckedOut ? AppColors.completedText : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
