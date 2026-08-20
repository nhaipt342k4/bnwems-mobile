import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
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
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHẤM CÔNG',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLabel,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lịch sử điểm danh',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppColors.warmTextDark,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (timeline.isEmpty) ...[
              const EmptyStateWidget(
                message: 'Chưa có lịch trình chấm công nào.',
                icon: LucideIcons.clock,
              ),
            ] else ...[
              Stack(
                children: [
                  Positioned(
                    left: 11,
                    top: 12,
                    bottom: 12,
                    child: Container(width: 2, color: const Color(0xFFEAD8B7)),
                  ),
                  Column(
                    children: timeline.map((entry) {
                      final plan = entry['plan'];
                      final assignee = entry['assignee'];
                      final isCheckedIn = assignee.isCheckedIn;
                      final isCheckedOut = assignee.isCheckedOut;

                      String statusLabel = 'Chưa điểm danh';
                      Color statusBg = const Color(0xFFF7EEDD);
                      Color statusFg = const Color(0xFF8C7355);

                      if (isCheckedOut) {
                        statusLabel = 'Đã check-out';
                        statusBg = const Color(0xFFDCFCE7);
                        statusFg = const Color(0xFF15803D);
                      } else if (isCheckedIn) {
                        statusLabel = 'Đang làm việc';
                        statusBg = const Color(0xFFF0FDF4);
                        statusFg = const Color(0xFF16A34A);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0, left: 26.0),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warmTextDark,
                                        fontFamily: 'serif',
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusFg,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Formatters.formatDate(plan.startTime)} · ${Formatters.formatTime(plan.startTime)}',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                              ),
                              Text(
                                'Check-in: ${isCheckedIn ? Formatters.formatDateTime(assignee.checkInAt) : '--'}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isCheckedIn ? const Color(0xFF16A34A) : AppColors.warmTextMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check-out: ${isCheckedOut ? Formatters.formatDateTime(assignee.checkOutAt) : '--'}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isCheckedOut ? const Color(0xFF16A34A) : AppColors.warmTextMuted,
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
