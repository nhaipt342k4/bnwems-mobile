import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class TaskStatisticGrid extends StatelessWidget {
  final int todayCount;
  final int pendingConfirmationCount;

  const TaskStatisticGrid({
    super.key,
    required this.todayCount,
    required this.pendingConfirmationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card 1: Lịch trình hôm nay
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Gold Bar Accent
                Container(
                  height: 3,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HÔM NAY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLabel,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Icon(LucideIcons.fileText, size: 16, color: AppColors.goldPrimary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$todayCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppColors.warmTextDark,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kế hoạch công việc',
                  style: TextStyle(fontSize: 11.5, color: AppColors.warmTextMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card 2: Chờ xác nhận
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Gold Bar Accent
                Container(
                  height: 3,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHỜ XÁC NHẬN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLabel,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Icon(LucideIcons.mapPin, size: 16, color: AppColors.goldPrimary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$pendingConfirmationCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppColors.warmTextDark,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Cần Lead phê duyệt',
                  style: TextStyle(fontSize: 11.5, color: AppColors.warmTextMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
