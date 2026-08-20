import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../tasks/data/models/work_task_models.dart';

/// Card "Việc đang làm" ở trang chủ: hiển thị lịch mà nhân viên ĐANG check-in dở (chưa check-out) kèm nút Check-out nhanh.
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE8DC)),
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
          // Header status & time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ĐANG THỰC HIỆN',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (checkInTime.isNotEmpty) ...[
                const Icon(LucideIcons.clock, size: 14, color: AppColors.warmTextMuted),
                const SizedBox(width: 4),
                Text(
                  'Check-in $checkInTime',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.warmTextMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Task Title
          Text(
            plan.taskName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C241E),
              fontFamily: 'serif',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // Codes line
          Text(
            [plan.planCode, if (plan.orderCode.isNotEmpty) plan.orderCode].join(' · '),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
          ),
          if (location != null && location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.mapPin, size: 15, color: AppColors.goldPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF3D332B)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          // Vibrant Warm Gold Check-Out Button
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
              onPressed: _loading ? null : _handleCheckOut,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.logOut, size: 18, color: Colors.white),
              label: Text(
                _loading ? 'Đang check-out...' : 'Check-out ngay',
                style: const TextStyle(
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
        ],
      ),
    );
  }
}
