import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/work_task_models.dart';

class CurrentTaskCard extends StatelessWidget {
  final SchedulePlan plan;
  final SchedulePlanAssignee? myAssignee;
  final SchedulePlan? activePlan;
  final VoidCallback? onCheckInPressed;

  const CurrentTaskCard({
    super.key,
    required this.plan,
    this.myAssignee,
    this.activePlan,
    this.onCheckInPressed,
  });

  Map<String, Color> _getStatusColors(SchedulePlanStatus status) {
    switch (status) {
      case 'PENDING':
        return {'bg': const Color(0xFFFFF9EE), 'fg': const Color(0xFFD97706)};
      case 'CONFIRMED':
        return {'bg': const Color(0xFFE0F2FE), 'fg': const Color(0xFF0284C7)};
      case 'IN_PROGRESS':
        return {'bg': const Color(0xFFF0FDF4), 'fg': const Color(0xFF16A34A)};
      case 'COMPLETED':
        return {'bg': const Color(0xFFDCFCE7), 'fg': const Color(0xFF15803D)};
      case 'CANCELLED':
        return {'bg': const Color(0xFFFEF2F2), 'fg': const Color(0xFFB91C1C)};
      default:
        return {'bg': const Color(0xFFF7EEDD), 'fg': const Color(0xFF8C7355)};
    }
  }

  String _getStatusLabel(SchedulePlanStatus status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'IN_PROGRESS':
        return 'Đang thực hiện';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _getTypeLabel(WorkTaskCode code) {
    switch (code) {
      case 'SURVEY':
        return 'Khảo sát hiện trường';
      case 'SETUP':
        return 'Lắp đặt thiết bị';
      case 'COLLECT':
        return 'Thu hồi thiết bị';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _getStatusColors(plan.status);
    final isCheckedIn = myAssignee?.isCheckedIn ?? false;
    final canCheckIn = plan.status != 'CANCELLED' && plan.status != 'COMPLETED' && !isCheckedIn;
    final hasOtherActivePlan = activePlan != null && activePlan!.planId != plan.planId;

    return InkWell(
      onTap: () {
        final user = context.read<AuthProvider>().user;
        if (user != null && user.isManager && plan.orderId.isNotEmpty) {
          context.push('/manager/orders/${plan.orderId}');
        } else {
          context.push('/staff/tasks/${plan.planId}');
        }
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status Badge (Left) + Plan Code (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColors['bg']!,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(plan.status),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: statusColors['fg']!,
                    ),
                  ),
                ),
                Text(
                  plan.planCode,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              plan.taskName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w400,
                color: AppColors.warmTextDark,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatOrderEvent(plan.orderCode, plan.eventName),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.goldPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Row 3: Task Type Badge & Role Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getTypeLabel(plan.taskCode),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLabel,
                    ),
                  ),
                ),
                if (myAssignee != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: myAssignee!.role == 'LEAD' ? const Color(0xFFF3E8FF) : const Color(0xFFF7F2EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      myAssignee!.role == 'LEAD' ? 'Trưởng nhóm' : 'Kỹ thuật viên',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: myAssignee!.role == 'LEAD' ? const Color(0xFF7E22CE) : AppColors.goldLabel,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0E8DC)),
            ),

            // Row 4: Metadata Info (Time & Location)
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF7F2EA),
                  ),
                  child: const Icon(LucideIcons.clock, size: 14, color: AppColors.goldPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${Formatters.formatDate(plan.startTime)} · ${Formatters.formatTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmTextDark,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.location != null && plan.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF7F2EA),
                    ),
                    child: const Icon(LucideIcons.mapPin, size: 14, color: AppColors.goldPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plan.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmTextDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            if (canCheckIn && hasOtherActivePlan) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
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

            // Row 5: Action buttons
            Row(
              children: [
                if (canCheckIn) ...[
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: onCheckInPressed,
                        icon: Icon(hasOtherActivePlan ? LucideIcons.lock : LucideIcons.checkCircle2, size: 16),
                        label: Text(hasOtherActivePlan ? 'Đã khóa' : 'Check-in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasOtherActivePlan ? Colors.grey.shade300 : AppColors.goldPrimary,
                          foregroundColor: hasOtherActivePlan ? Colors.grey.shade700 : Colors.white,
                          elevation: 2,
                          shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/staff/tasks/${plan.planId}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C241E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Xem chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
