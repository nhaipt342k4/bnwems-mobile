import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/work_task_models.dart';

class UpcomingEventAlert extends StatelessWidget {
  final List<SchedulePlan> plans;

  const UpcomingEventAlert({
    super.key,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0DFBD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.bell, size: 16, color: AppColors.goldPrimary),
              SizedBox(width: 8),
              Text(
                'SỰ KIỆN SẮP DIỄN RA HÔM NAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLabel,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...plans.take(2).map(
                (plan) => InkWell(
                  onTap: () => context.push('/staff/tasks/${plan.planId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.eventName ?? plan.taskName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warmTextDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${plan.orderCode} · ${Formatters.formatDate(plan.startTime)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.warmTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.warmTextMuted),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
