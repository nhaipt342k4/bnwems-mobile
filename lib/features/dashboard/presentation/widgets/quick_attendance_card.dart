import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.warmInputBg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.clock, color: AppColors.warmTextMuted, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Không có công việc nào đang chờ điểm danh.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.warmTextMuted,
                ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE8DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.checkCircle2,
                color: AppColors.goldPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCheckedIn
                      ? 'ĐÃ ĐIỂM DANH (${Formatters.formatTime(myAssignee!.checkInAt)})'
                      : 'ĐIỂM DANH KHẨN CẤP HÔM NAY',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan!.taskName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              color: Color(0xFF2C241E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan!.orderCode} · ${Formatters.formatTime(plan!.startTime)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.goldPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (!isCheckedIn) ...[
            if (hasOtherActivePlan) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn không được check-in khi chưa hoàn thành (check-out) công việc ${activePlan!.planCode} (${activePlan!.taskName}).',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onCheckInPressed,
                icon: Icon(hasOtherActivePlan ? LucideIcons.lock : LucideIcons.checkCircle2, size: 18),
                label: Text(hasOtherActivePlan ? 'Nút Check-in đã bị khóa' : 'Check-in Ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasOtherActivePlan ? Colors.grey.shade300 : AppColors.goldPrimary,
                  foregroundColor: hasOtherActivePlan ? Colors.grey.shade700 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else if (!isCheckedOut) ...[
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xFFC59B63), Color(0xFFA87E46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC59B63).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onCheckOutPressed,
                icon: const Icon(LucideIcons.logOut, size: 18, color: Colors.white),
                label: const Text(
                  'Check-out ngay',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
