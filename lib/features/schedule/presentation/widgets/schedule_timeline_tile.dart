import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_role_badge.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/data/models/work_task_models.dart';

/// Một mốc trên cây timeline lịch trình ngày: cột giờ + rail chấm (màu theo trạng thái, có đường nối
/// giữa các mốc) bên trái, thẻ nội dung gọn bên phải. Dùng riêng cho ScheduleCalendarScreen — KHÔNG
/// đụng CurrentTaskCard (vẫn dùng ở Dashboard/Danh sách việc).
class ScheduleTimelineTile extends StatelessWidget {
  final SchedulePlan plan;
  final SchedulePlanAssignee? myAssignee;
  final SchedulePlan? activePlan;
  final VoidCallback? onCheckInPressed;
  final bool isFirst;
  final bool isLast;

  const ScheduleTimelineTile({
    super.key,
    required this.plan,
    this.myAssignee,
    this.activePlan,
    this.onCheckInPressed,
    this.isFirst = false,
    this.isLast = false,
  });

  // (bg, fg) theo trạng thái — dot dùng fg làm màu đặc.
  ({Color bg, Color fg, String label}) _status(SchedulePlanStatus s) {
    switch (s) {
      case 'CONFIRMED':
        return (bg: AppColors.confirmedBg, fg: AppColors.confirmedText, label: 'Đã xác nhận');
      case 'IN_PROGRESS':
        return (bg: AppColors.inProgressBg, fg: AppColors.inProgressText, label: 'Đang thực hiện');
      case 'COMPLETED':
        return (bg: AppColors.completedBg, fg: AppColors.completedText, label: 'Hoàn thành');
      case 'CANCELLED':
        return (bg: AppColors.cancelledBg, fg: AppColors.cancelledText, label: 'Đã hủy');
      case 'PENDING':
      default:
        return (bg: AppColors.pendingBg, fg: AppColors.pendingText, label: 'Chờ xác nhận');
    }
  }

  ({Color bg, Color fg, IconData icon, String label}) _type(WorkTaskCode code) {
    switch (code) {
      case 'SURVEY':
        return (bg: AppColors.surveyBg, fg: AppColors.surveyText, icon: LucideIcons.clipboardList, label: 'Khảo sát hiện trường');
      case 'SETUP':
        return (bg: AppColors.setupBg, fg: AppColors.setupText, icon: LucideIcons.wrench, label: 'Lắp đặt thiết bị');
      case 'COLLECT':
        return (bg: AppColors.collectBg, fg: AppColors.collectText, icon: LucideIcons.packageOpen, label: 'Thu hồi thiết bị');
      default:
        return (bg: AppColors.surveyBg, fg: AppColors.surveyText, icon: LucideIcons.calendarClock, label: code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _status(plan.status);
    final ty = _type(plan.taskCode);
    final isCompleted = plan.status == 'COMPLETED';
    final isCancelled = plan.status == 'CANCELLED';
    final lineColor = AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Cột giờ ----
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

          // ---- Rail: đường nối + chấm ----
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(width: 2, height: 3, color: isFirst ? Colors.transparent : lineColor),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: st.fg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2.5),
                    boxShadow: [BoxShadow(color: st.fg.withValues(alpha: 0.25), blurRadius: 4, spreadRadius: 1)],
                  ),
                  child: isCompleted
                      ? const Icon(LucideIcons.check, size: 8, color: Colors.white)
                      : null,
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ---- Thẻ nội dung ----
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  final user = context.read<AuthProvider>().user;
                  if (user != null && user.isManager && plan.orderId.isNotEmpty) {
                    context.push('/manager/orders/${plan.orderId}');
                  } else {
                    context.push('/staff/tasks/${plan.planId}');
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: icon loại việc + tên việc/mã + trạng thái
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
                                  plan.taskName,
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
                          AppBadge(label: st.label, backgroundColor: st.bg, textColor: st.fg),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Đơn hàng / sự kiện
                      _infoRow(
                        LucideIcons.hash,
                        '${plan.orderCode}${plan.eventName != null && plan.eventName!.isNotEmpty ? ' · ${plan.eventName}' : ''}',
                        color: AppColors.primary,
                        bold: true,
                      ),
                      // Khách hàng
                      if (plan.customerName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _infoRow(LucideIcons.user, plan.customerName),
                      ],
                      // Địa điểm
                      if (plan.location != null && plan.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _infoRow(LucideIcons.mapPin, plan.location!),
                      ],

                      // Footer: vai trò + trạng thái chấm công / nút check-in
                      const SizedBox(height: 12),
                      Container(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (myAssignee != null) AppRoleBadge(roleName: myAssignee!.role),
                          const Spacer(),
                          _footer(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _footer(BuildContext context) {
    final isCheckedIn = myAssignee?.isCheckedIn ?? false;
    final checkedOut = myAssignee?.checkOutAt != null;
    final canCheckIn = plan.status != 'CANCELLED' && plan.status != 'COMPLETED' && !isCheckedIn;
    final hasOtherActivePlan = activePlan != null && activePlan!.planId != plan.planId;

    if (checkedOut) {
      return _stateChip(LucideIcons.checkCheck, 'Đã check-out', AppColors.completedText, AppColors.completedBg);
    }
    if (isCheckedIn) {
      final at = myAssignee?.checkInAt;
      return _stateChip(
        LucideIcons.checkCircle2,
        at != null ? 'Đã check-in ${Formatters.formatTime(at)}' : 'Đã check-in',
        AppColors.completedText,
        AppColors.completedBg,
      );
    }
    if (canCheckIn) {
      return ElevatedButton.icon(
        onPressed: onCheckInPressed,
        icon: Icon(hasOtherActivePlan ? LucideIcons.lock : LucideIcons.checkCircle2, size: 15),
        label: Text(hasOtherActivePlan ? 'Đã bị khóa' : 'Check-in', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasOtherActivePlan ? const Color(0xFFE2E8F0) : AppColors.primary,
          foregroundColor: hasOtherActivePlan ? AppColors.textSecondary : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _stateChip(IconData icon, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}
