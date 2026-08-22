import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
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
        backgroundColor: AppColors.goldPrimary,
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
          // 1. Banner vai trò Kỹ Thuật Viên (Soft Cream / Gold Theme)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0DFBD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF7F2EA),
                  ),
                  child: const Icon(LucideIcons.wrench, size: 18, color: AppColors.goldPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Bạn đang làm ',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF5C4E43), height: 1.4),
                      children: [
                        const TextSpan(
                          text: 'Kỹ thuật viên',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                        ),
                        TextSpan(
                          text: isSurvey
                              ? ' cho công việc Khảo sát hiện trường. Hãy xem lịch trình và liên hệ Trưởng nhóm bên dưới.'
                              : ' cho công việc này. Hãy xem lịch trình, liên hệ Trưởng nhóm và kiểm kê danh sách thiết bị bên dưới.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Lịch trình & Địa điểm (Schedule Card)
          Container(
            padding: const EdgeInsets.all(20),
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
                    Text(
                      widget.plan.planCode,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.plan.status == 'COMPLETED'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF7EEDD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        Formatters.formatStatus(widget.plan.status),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: widget.plan.status == 'COMPLETED'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF8C7355),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.plan.taskName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppColors.warmTextDark,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn hàng: ${Formatters.formatOrderEvent(widget.plan.orderCode, widget.plan.eventName)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                ),

                _buildRowInfo(
                  LucideIcons.clock,
                  'Thời gian thực hiện',
                  '${Formatters.formatDateTime(widget.plan.startTime)}${widget.plan.endTime != null ? ' - ${Formatters.formatTime(widget.plan.endTime)}' : ''}',
                ),
                const SizedBox(height: 14),
                _buildRowInfo(
                  LucideIcons.user,
                  'Khách hàng',
                  '${widget.plan.customerName}${widget.plan.customerPhone.isNotEmpty ? ' (${widget.plan.customerPhone})' : ''}',
                ),
                const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F2EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.userCheck, size: 22, color: AppColors.goldPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRƯỞNG NHÓM PHỤ TRÁCH',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLabel,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leader.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                      ),
                      if (leader.phone != null && leader.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          leader.phone!,
                          style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
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
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              padding: const EdgeInsets.all(20),
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
                      const Expanded(
                        child: Text(
                          'Checklist Kiểm đồ & Thiết bị',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$checkedCount/$totalCount đã kiểm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: checkedCount == totalCount ? const Color(0xFF16A34A) : AppColors.goldPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (totalCount > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFFAF6F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          checkedCount == totalCount ? const Color(0xFF16A34A) : AppColors.goldPrimary,
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
                        color: AppColors.warmInputBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Chưa có thông tin danh sách thiết bị cho công việc này.',
                        style: TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
                      ),
                    )
                  else
                    ...widget.items.map((item) {
                      final isChecked = _checkedItemIds.contains(item.itemId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFFF0FDF4) : const Color(0xFFFAF6F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isChecked ? const Color(0xFF86EFAC) : const Color(0xFFEFE8DC),
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
                          activeColor: const Color(0xFF16A34A),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isChecked ? const Color(0xFF15803D) : AppColors.warmTextDark,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            'Số lượng: ${item.quantity} ${item.unit}${item.source != null ? ' · Nguồn: ${item.source}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F2EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.package, size: 18, color: AppColors.goldPrimary),
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
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFF9EE),
          ),
          child: Icon(icon, size: 16, color: AppColors.goldPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.warmTextMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.warmTextDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
