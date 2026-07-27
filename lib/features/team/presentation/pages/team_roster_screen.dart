import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/data/models/work_task_models.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

class TeamMemberEntry {
  final String userId;
  final String fullName;
  final List<Map<String, dynamic>> plans;

  TeamMemberEntry({
    required this.userId,
    required this.fullName,
    required this.plans,
  });
}

class TeamRosterScreen extends StatelessWidget {
  const TeamRosterScreen({super.key});

  List<TeamMemberEntry> _buildTeamRoster(List<SchedulePlan> myPlans, String currentUserId) {
    final leaderPlans = myPlans.where((plan) {
      final assignee = plan.assignees.cast<SchedulePlanAssignee?>().firstWhere(
            (a) => a?.userId == currentUserId,
            orElse: () => null,
          );
      return assignee?.role == 'LEAD';
    }).toList();

    final Map<String, Map<String, dynamic>> rosterMap = {};

    for (final plan in leaderPlans) {
      for (final assignee in plan.assignees) {
        if (assignee.userId == currentUserId) continue; // Skip self

        if (!rosterMap.containsKey(assignee.userId)) {
          rosterMap[assignee.userId] = {
            'userId': assignee.userId,
            'fullName': assignee.fullName,
            'plans': <Map<String, dynamic>>[],
          };
        }

        (rosterMap[assignee.userId]!['plans'] as List<Map<String, dynamic>>).add({
          'planId': plan.planId,
          'taskName': plan.taskName,
          'startTime': plan.startTime,
          'planStatus': plan.status,
        });
      }
    }

    return rosterMap.values
        .map(
          (v) => TeamMemberEntry(
            userId: v['userId'] as String,
            fullName: v['fullName'] as String,
            plans: v['plans'] as List<Map<String, dynamic>>,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final taskProvider = context.watch<TaskProvider>();

    final roster = user != null ? _buildTeamRoster(taskProvider.myPlans, user.id) : <TeamMemberEntry>[];
    final allPlanEntries = roster.expand((member) => member.plans).toList();
    final completedCount = allPlanEntries.where((entry) => entry['planStatus'] == 'COMPLETED').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const AppHeader(title: 'Nhóm của tôi', backHref: '/staff/profile'),
            const SizedBox(height: 8),

            if (roster.isEmpty) ...[
              const EmptyStateWidget(
                message: 'Bạn hiện không giữ vai trò Trưởng nhóm (LEAD) ở kế hoạch nào.',
                icon: LucideIcons.users,
              ),
            ] else ...[
              // Summary Header Card (Blue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng quan nhóm', style: TextStyle(fontSize: 13, color: Color(0xFFDBEAFE))),
                    const SizedBox(height: 4),
                    Text(
                      '${roster.length} kỹ thuật viên · $completedCount/${allPlanEntries.length} kế hoạch hoàn thành',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Roster Cards List
              ...roster.map(
                (member) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(Formatters.getInitial(member.fullName), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          ),
                          const SizedBox(width: 8),
                          Text(member.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...member.plans.map(
                        (p) => InkWell(
                          onTap: () => context.push('/staff/tasks/${p['planId']}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['taskName'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text(Formatters.formatDate(p['startTime'] as String), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                                AppBadge(
                                  label: Formatters.formatStatus(p['planStatus'] as String),
                                  backgroundColor: AppColors.primaryLight,
                                  textColor: AppColors.primaryDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
