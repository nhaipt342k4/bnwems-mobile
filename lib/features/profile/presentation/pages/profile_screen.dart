import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_role_badge.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = authProvider.user;

    final leaderPlans = user != null
        ? taskProvider.myPlans.where((plan) {
            final assignee = taskProvider.getMyAssignee(plan, user.id);
            return assignee?.role == 'LEAD';
          }).toList()
        : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const AppHeader(title: 'Cá nhân'),
            const SizedBox(height: 8),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      Formatters.getInitial(user?.fullName),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Nhân viên',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  if (user != null) AppRoleBadge(roleName: user.role.roleName),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User Info Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Tên đăng nhập', user?.username ?? '--'),
                  const Divider(height: 20),
                  _buildDetailRow('Số điện thoại', user?.phone ?? '--'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // My Team Navigation (for Lead role)
            if (user != null && user.isLead) ...[
              InkWell(
                onTap: () => context.push('/staff/team'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.users, color: AppColors.leaderPurple, size: 20),
                          SizedBox(width: 12),
                          Text('Nhóm của tôi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Leader View Section
            if (leaderPlans.isNotEmpty) ...[
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
                    const Text(
                      'Kế hoạch đảm nhận Trưởng nhóm (Leader View)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...leaderPlans.map(
                      (plan) => InkWell(
                        onTap: () => context.push('/staff/tasks/${plan.planId}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plan.taskName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    Text('${plan.orderCode} · ${Formatters.formatDate(plan.startTime)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              AppBadge(
                                label: Formatters.formatStatus(plan.status),
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
              const SizedBox(height: 16),
            ],

            // Logout Button
            AppButton(
              text: 'Đăng xuất',
              variant: AppButtonVariant.danger,
              isFullWidth: true,
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/auth/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
