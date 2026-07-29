import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../tasks/data/models/work_task_models.dart';

class QuickAttendanceCard extends StatelessWidget {
  final SchedulePlan? plan;
  final SchedulePlanAssignee? myAssignee;
  final SchedulePlan? activePlan;
  final VoidCallback? onCheckInPressed;
  final VoidCallback? onCheckOutPressed;

  const QuickAttendanceCard({
    super.key,
    this.plan,
    this.myAssignee,
    this.activePlan,
    this.onCheckInPressed,
    this.onCheckOutPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (plan == null || myAssignee == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.clock, color: AppColors.textMuted, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Không có công việc nào đang chờ điểm danh.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final isCheckedIn = myAssignee!.isCheckedIn;
    final isCheckedOut = myAssignee!.isCheckedOut;

    final hasOtherActivePlan = activePlan != null && plan != null && activePlan!.planId != plan!.planId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCheckedIn ? const Color(0xFF1E293B) : AppColors.surface, // Dark background if checked-in
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheckedIn ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCheckedIn ? Colors.black.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.checkCircle2,
                color: isCheckedIn ? const Color(0xFF38BDF8) : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCheckedIn
                      ? 'ĐÃ ĐIỂM DANH (${Formatters.formatTime(myAssignee!.checkInAt)})'
                      : 'ĐIỂM DANH KHẨN CẤP HÔM NAY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isCheckedIn ? const Color(0xFF38BDF8) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan!.taskName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isCheckedIn ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan!.orderCode} · ${Formatters.formatTime(plan!.startTime)}',
            style: TextStyle(
              fontSize: 12,
              color: isCheckedIn ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          if (!isCheckedIn) ...[
            if (hasOtherActivePlan) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn không được check-in khi chưa hoàn thành (check-out) công việc ${activePlan!.planCode} (${activePlan!.taskName}).',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckInPressed,
                icon: Icon(hasOtherActivePlan ? LucideIcons.lock : LucideIcons.checkCircle2, size: 18),
                label: Text(hasOtherActivePlan ? 'Nút Check-in đã bị khóa' : 'Check-in Ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasOtherActivePlan ? Colors.grey.shade300 : AppColors.primary,
                  foregroundColor: hasOtherActivePlan ? Colors.grey.shade700 : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else if (!isCheckedOut) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckOutPressed,
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Check-out Ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.checkCheck, color: Color(0xFF4ADE80), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Đã hoàn thành Check-in & Check-out (${Formatters.formatTime(myAssignee!.checkOutAt)})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4ADE80)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
