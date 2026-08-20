import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/data/models/work_task_models.dart';

/// Một mốc trên cây timeline lịch trình ngày: cột giờ + rail chấm màu vàng kim bên trái, thẻ nội dung bo tròn bên phải.
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

  ({Color bg, Color fg, String label}) _status(SchedulePlanStatus s) {
    switch (s) {
      case 'CONFIRMED':
        return (bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0284C7), label: 'Đã xác nhận');
      case 'IN_PROGRESS':
        return (bg: const Color(0xFFF7EEDD), fg: const Color(0xFF8C7355), label: 'Đang thực hiện');
      case 'COMPLETED':
        return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A), label: 'Hoàn thành');
      case 'CANCELLED':
        return (bg: AppColors.cancelledBg, fg: AppColors.cancelledText, label: 'Đã hủy');
      case 'PENDING':
      default:
        return (bg: const Color(0xFFF7F2EA), fg: AppColors.goldLabel, label: 'Chờ xác nhận');
    }
  }

  ({Color bg, Color fg, IconData icon, String label}) _type(WorkTaskCode code) {
    switch (code) {
      case 'SURVEY':
        return (bg: const Color(0xFFF7F2EA), fg: AppColors.goldPrimary, icon: LucideIcons.clipboardList, label: 'Khảo sát hiện trường');
      case 'SETUP':
        return (bg: const Color(0xFFF7F2EA), fg: AppColors.goldPrimary, icon: LucideIcons.wrench, label: 'Lắp đặt thiết bị');
      case 'COLLECT':
        return (bg: const Color(0xFFF7F2EA), fg: AppColors.goldPrimary, icon: LucideIcons.packageOpen, label: 'Thu hồi thiết bị');
      default:
        return (bg: const Color(0xFFF7F2EA), fg: AppColors.goldPrimary, icon: LucideIcons.calendarClock, label: code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _status(plan.status);
    final isCompleted = plan.status == 'COMPLETED';
    final isCancelled = plan.status == 'CANCELLED';
    const lineColor = Color(0xFFEAD8B7);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Cột giờ ----
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.formatTime(plan.startTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'serif',
                      color: AppColors.warmTextDark,
                    ),
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
          const SizedBox(width: 10),

          // ---- Rail: đường nối + chấm ----
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(width: 2, height: 4, color: isFirst ? Colors.transparent : lineColor),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.warmBackground, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
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
                borderRadius: BorderRadius.circular(28),
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
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
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
                                  plan.taskName,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: st.bg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              st.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: st.fg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                      ),

                      // Order info row
                      _infoRow(
                        LucideIcons.calendar,
                        Formatters.formatOrderEvent(plan.orderCode, plan.eventName),
                        color: AppColors.goldPrimary,
                        bold: true,
                      ),
                      // Customer row
                      if (plan.customerName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _infoRow(LucideIcons.building2, plan.customerName),
                      ],
                      // Location row
                      if (plan.location != null && plan.location!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _infoRow(LucideIcons.mapPin, plan.location!),
                      ],

                      // Footer row
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (myAssignee != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F2EA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.userCheck, size: 12, color: AppColors.goldLabel),
                                  const SizedBox(width: 4),
                                  Text(
                                    Formatters.formatRole(myAssignee!.role),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: myAssignee!.role == 'LEAD' ? const Color(0xFF7E22CE) : AppColors.goldLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
        Icon(icon, size: 15, color: color ?? const Color(0xFF8C7B6B)),
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

  Widget _footer(BuildContext context) {
    final isCheckedIn = myAssignee?.isCheckedIn ?? false;
    final checkedOut = myAssignee?.checkOutAt != null;
    final canCheckIn = plan.status != 'CANCELLED' && plan.status != 'COMPLETED' && !isCheckedIn;
    final hasOtherActivePlan = activePlan != null && activePlan!.planId != plan.planId;

    if (checkedOut) {
      return _stateChip(LucideIcons.checkCheck, 'Đã check-out', const Color(0xFF16A34A), const Color(0xFFDCFCE7));
    }
    if (isCheckedIn) {
      final at = myAssignee?.checkInAt;
      return _stateChip(
        LucideIcons.checkCircle2,
        at != null ? 'Đã check-in ${Formatters.formatTime(at)}' : 'Đã check-in',
        Colors.white,
        const Color(0xFF5C4E43),
        iconColor: const Color(0xFFF0DFBD),
      );
    }
    if (canCheckIn) {
      return SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: onCheckInPressed,
          icon: Icon(hasOtherActivePlan ? LucideIcons.lock : LucideIcons.checkCircle2, size: 15),
          label: Text(hasOtherActivePlan ? 'Đã bị khóa' : 'Check-in', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasOtherActivePlan ? const Color(0xFFE2E8F0) : AppColors.goldPrimary,
            foregroundColor: hasOtherActivePlan ? AppColors.textSecondary : Colors.white,
            elevation: 2,
            shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _stateChip(IconData icon, String label, Color fg, Color bg, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}
