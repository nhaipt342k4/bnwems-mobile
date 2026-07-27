import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_role_badge.dart';
import '../../data/models/work_task_models.dart';

class CurrentTaskCard extends StatelessWidget {
  final SchedulePlan plan;
  final SchedulePlanAssignee? myAssignee;
  final VoidCallback? onCheckInPressed;

  const CurrentTaskCard({
    super.key,
    required this.plan,
    this.myAssignee,
    this.onCheckInPressed,
  });

  Map<String, Color> _getStatusColors(SchedulePlanStatus status) {
    switch (status) {
      case 'PENDING':
        return {'bg': AppColors.pendingBg, 'fg': AppColors.pendingText};
      case 'CONFIRMED':
        return {'bg': AppColors.confirmedBg, 'fg': AppColors.confirmedText};
      case 'IN_PROGRESS':
        return {'bg': AppColors.inProgressBg, 'fg': AppColors.inProgressText};
      case 'COMPLETED':
        return {'bg': AppColors.completedBg, 'fg': AppColors.completedText};
      case 'CANCELLED':
        return {'bg': AppColors.cancelledBg, 'fg': AppColors.cancelledText};
      default:
        return {'bg': AppColors.pendingBg, 'fg': AppColors.pendingText};
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

  Map<String, Color> _getTypeColors(WorkTaskCode code) {
    switch (code) {
      case 'SURVEY':
        return {'bg': AppColors.surveyBg, 'fg': AppColors.surveyText};
      case 'SETUP':
        return {'bg': AppColors.setupBg, 'fg': AppColors.setupText};
      case 'COLLECT':
        return {'bg': AppColors.collectBg, 'fg': AppColors.collectText};
      default:
        return {'bg': AppColors.surveyBg, 'fg': AppColors.surveyText};
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
    final typeColors = _getTypeColors(plan.taskCode);
    final isCheckedIn = myAssignee?.isCheckedIn ?? false;
    final canCheckIn = plan.status != 'CANCELLED' && plan.status != 'COMPLETED' && !isCheckedIn;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status Badge (Left) + Plan Code (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge(
                label: _getStatusLabel(plan.status),
                backgroundColor: statusColors['bg']!,
                textColor: statusColors['fg']!,
              ),
              Text(
                plan.planCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Task Name + Order Code / Event Name
          Text(
            plan.taskName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.orderCode}${plan.eventName != null ? ' · ${plan.eventName}' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Task Type Badge
          AppBadge(
            label: _getTypeLabel(plan.taskCode),
            backgroundColor: typeColors['bg']!,
            textColor: typeColors['fg']!,
          ),
          const SizedBox(height: 12),

          // Row 4: Metadata Info (Time & Location)
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${Formatters.formatDate(plan.startTime)} · ${Formatters.formatTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (plan.location != null && plan.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plan.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Row 5: Role Badge
          if (myAssignee != null) AppRoleBadge(roleName: myAssignee!.role),
          const SizedBox(height: 12),

          // Row 6: Action buttons
          Row(
            children: [
              if (canCheckIn) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCheckInPressed,
                    icon: const Icon(LucideIcons.checkCircle2, size: 16),
                    label: const Text('Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/staff/tasks/${plan.planId}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Chi tiết'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
