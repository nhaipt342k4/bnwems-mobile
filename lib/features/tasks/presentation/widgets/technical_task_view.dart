import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../authentication/data/models/auth_user.dart';
import '../../data/models/work_task_models.dart';
import '../providers/task_provider.dart';

class TechnicalTaskView extends StatefulWidget {
  final SchedulePlan plan;
  final SchedulePlanAssignee? myAssignee;
  final AuthUser? user;
  final TaskProvider taskProvider;
  final List<WorkTaskItem> items;

  const TechnicalTaskView({
    super.key,
    required this.plan,
    required this.myAssignee,
    required this.user,
    required this.taskProvider,
    required this.items,
  });

  @override
  State<TechnicalTaskView> createState() => _TechnicalTaskViewState();
}

class _TechnicalTaskViewState extends State<TechnicalTaskView> {
  final Set<String> _checkedItemIds = {};

  void _copyPhoneNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép số điện thoại Trưởng nhóm: $phoneNumber'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leader = widget.plan.assignees.firstWhere(
      (a) => a.role == 'LEAD',
      orElse: () => SchedulePlanAssignee(
        assigneeId: '',
        planId: widget.plan.planId,
        userId: '',
        fullName: 'Chưa phân công',
        role: 'LEAD',
      ),
    );

    final checkedCount = _checkedItemIds.length;
    final totalCount = widget.items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
    final isSurvey = widget.plan.taskCode == 'SURVEY';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Banner vai trò Kỹ Thuật Viên
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.confirmedBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.confirmedText.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.wrench, size: 18, color: AppColors.confirmedText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSurvey
                        ? 'Bạn đang làm Kỹ thuật viên cho công việc Khảo sát hiện trường. Hãy xem lịch trình và liên hệ Trưởng nhóm bên dưới.'
                        : 'Bạn đang làm Kỹ thuật viên cho công việc này. Hãy xem lịch trình, liên hệ Trưởng nhóm và kiểm kê danh sách thiết bị bên dưới.',
                    style: const TextStyle(fontSize: 12, color: AppColors.confirmedText, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Lịch trình & Địa điểm (Schedule Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.plan.planCode,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    AppBadge(
                      label: Formatters.formatStatus(widget.plan.status),
                      backgroundColor: AppColors.primaryLight,
                      textColor: AppColors.primaryDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.plan.taskName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn hàng: ${widget.plan.orderCode}${widget.plan.eventName != null ? ' · ${widget.plan.eventName}' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const Divider(height: 24),

                _buildRowInfo(
                  LucideIcons.clock,
                  'Thời gian thực hiện',
                  '${Formatters.formatDateTime(widget.plan.startTime)}${widget.plan.endTime != null ? ' - ${Formatters.formatTime(widget.plan.endTime)}' : ''}',
                ),
                const SizedBox(height: 10),
                _buildRowInfo(
                  LucideIcons.user,
                  'Khách hàng',
                  '${widget.plan.customerName}${widget.plan.customerPhone.isNotEmpty ? ' (${widget.plan.customerPhone})' : ''}',
                ),
                const SizedBox(height: 10),
                _buildRowInfo(
                  LucideIcons.mapPin,
                  'Địa chỉ hiện trường',
                  widget.plan.location != null && widget.plan.location!.trim().isNotEmpty
                      ? widget.plan.location!
                      : (widget.plan.customerAddress.isNotEmpty ? widget.plan.customerAddress : 'Chưa có địa chỉ'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Thông tin Trưởng nhóm (Team Leader Contact Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.userCheck, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRƯỞNG NHÓM PHỤ TRÁCH',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leader.fullName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (leader.phone != null && leader.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          leader.phone!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (leader.phone != null && leader.phone!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _copyPhoneNumber(leader.phone!),
                    icon: const Icon(LucideIcons.phoneCall, size: 14),
                    label: const Text('Gọi / Lấy số'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Checklist Đồ đạc & Thiết bị (chỉ hiển thị với các công việc có thiết bị như Lắp đặt / Thu hồi, ẩn ở Khảo sát)
          if (!isSurvey) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Checklist Kiểm đồ & Thiết bị',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (totalCount > 0)
                        Text(
                          '$checkedCount/$totalCount đã kiểm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: checkedCount == totalCount ? AppColors.completedText : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (totalCount > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          checkedCount == totalCount ? AppColors.completedText : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Chưa có thông tin danh sách thiết bị cho công việc này.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    )
                  else
                    ...widget.items.map((item) {
                      final isChecked = _checkedItemIds.contains(item.itemId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? AppColors.completedBg.withValues(alpha: 0.5) : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isChecked ? AppColors.completedText.withValues(alpha: 0.3) : AppColors.borderLight,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _checkedItemIds.add(item.itemId);
                              } else {
                                _checkedItemIds.remove(item.itemId);
                              }
                            });
                          },
                          activeColor: AppColors.completedText,
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isChecked ? AppColors.completedText : AppColors.textPrimary,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            'Số lượng: ${item.quantity} ${item.unit}${item.source != null ? ' · Nguồn: ${item.source}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.package, size: 18, color: AppColors.primary),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRowInfo(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
