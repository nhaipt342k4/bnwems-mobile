import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../tasks/data/models/work_task_models.dart';

/// Card "Việc đang làm" ở trang chủ: hiển thị lịch mà nhân viên ĐANG check-in dở (chưa check-out) kèm nút
/// Check-out nhanh. Nguồn dữ liệu: GET /schedule-plans/active (TaskProvider.activeCheckInPlans).
class ActiveCheckInCard extends StatefulWidget {
  final SchedulePlan plan;
  final SchedulePlanAssignee? myAssignee;

  /// Thực hiện check-out (thường là taskProvider.checkOut). Ném lỗi nếu thất bại để card hiện thông báo.
  final Future<void> Function() onCheckOut;

  const ActiveCheckInCard({
    super.key,
    required this.plan,
    required this.onCheckOut,
    this.myAssignee,
  });

  @override
  State<ActiveCheckInCard> createState() => _ActiveCheckInCardState();
}

class _ActiveCheckInCardState extends State<ActiveCheckInCard> {
  bool _loading = false;

  String _checkInTimeLabel() {
    final raw = widget.myAssignee?.checkInAt;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = Formatters.parseVietnamDateTime(raw);
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleCheckOut() async {
    // Lấy messenger TRƯỚC await: sau khi check-out thành công card bị gỡ khỏi cây widget (provider cập
    // nhật activeCheckInPlans) nên không dùng context của card sau async gap được.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.onCheckOut();
      messenger.showSnackBar(
        SnackBar(content: const Text('Đã check-out thành công'), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Check-out thất bại: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final checkInTime = _checkInTimeLabel();
    final location = plan.location;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: Colors.green.shade500, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'ĐANG THỰC HIỆN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (checkInTime.isNotEmpty) ...[
                Icon(LucideIcons.clock, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Check-in $checkInTime', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(plan.taskName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            [plan.planCode, if (plan.orderCode.isNotEmpty) plan.orderCode].join(' · '),
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          if (location != null && location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Expanded(child: Text(location, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _handleCheckOut,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.logOut, size: 18),
              label: Text(_loading ? 'Đang check-out...' : 'Check-out ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
