import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';

class AppRoleBadge extends StatelessWidget {
  final String roleName;

  const AppRoleBadge({
    super.key,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    final isLead = roleName.toUpperCase() == 'LEAD' ||
        roleName.toLowerCase().contains('leader') ||
        roleName.toLowerCase().contains('trưởng nhóm');

    if (isLead) {
      return const AppBadge(
        label: 'Trưởng nhóm',
        backgroundColor: AppColors.leaderPurpleBg,
        textColor: AppColors.leaderPurple,
      );
    }

    return const AppBadge(
      label: 'Kỹ thuật viên',
      backgroundColor: AppColors.primaryLight,
      textColor: AppColors.primaryDark,
    );
  }
}
