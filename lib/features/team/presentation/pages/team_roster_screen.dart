import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
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
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Nhóm của tôi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.warmTextDark,
            fontFamily: 'serif',
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 18, color: Color(0xFF8C7355)),
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            if (roster.isEmpty) ...[
              const EmptyStateWidget(
                message: 'Bạn hiện không giữ vai trò Trưởng nhóm ở kế hoạch nào.',
                icon: LucideIcons.users,
              ),
            ] else ...[
              // Summary Header Card (Warm Gold)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG QUAN NHÓM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFF7ED),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${roster.length} kỹ thuật viên · $completedCount/${allPlanEntries.length} kế hoạch hoàn thành',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Roster Cards List
              ...roster.map(
                (member) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF7F2EA),
                            ),
                            child: Center(
                              child: Text(
                                Formatters.getInitial(member.fullName),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldPrimary,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            member.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmTextDark,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                      ),
                      ...member.plans.map(
                        (p) => InkWell(
                          onTap: () => context.push('/staff/tasks/${p['planId']}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['taskName'] as String,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.warmTextDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.formatDate(p['startTime'] as String),
                                      style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p['planStatus'] == 'COMPLETED' ? const Color(0xFFDCFCE7) : const Color(0xFFF7EEDD),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    Formatters.formatStatus(p['planStatus'] as String),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: p['planStatus'] == 'COMPLETED' ? const Color(0xFF16A34A) : const Color(0xFF8C7355),
                                    ),
                                  ),
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
