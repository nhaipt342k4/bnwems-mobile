import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            // Header Title
            const Text(
              'Cá nhân',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: AppColors.warmTextDark,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 18),

            // Profile Main Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF9EE),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF0E8DC)),
              ),
              child: Column(
                children: [
                  // Gold Avatar Circle with Dotted Border Ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF0DFBD), width: 1.5),
                    ),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD4A359),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4A359).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          Formatters.getInitial(user?.fullName),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'Nhân viên',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF0DFBD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.formatRole(user.role.roleName),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8C7456),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User Info Details Card (Tên đăng nhập & Số điện thoại)
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  _buildDetailRow('Tên đăng nhập', user?.username ?? '--'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                  ),
                  _buildDetailRow('Số điện thoại', user?.phone ?? '--'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Actions Card
            Container(
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
              child: Column(
                children: [
                  // Action 1: Cập nhật hồ sơ cá nhân
                  InkWell(
                    onTap: () => context.push('/staff/profile/edit'),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF9EE),
                            ),
                            child: const Icon(
                              LucideIcons.userCog,
                              color: AppColors.goldPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cập nhật hồ sơ cá nhân',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warmTextDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tên, ảnh và thông tin liên hệ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warmTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Color(0xFFD1C4B4), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0xFFF0E8DC)),

                  // Action 2: Đổi mật khẩu
                  InkWell(
                    onTap: () => context.push('/staff/profile/change-password'),
                    borderRadius: BorderRadius.vertical(
                      bottom: (user != null && user.isLead) ? Radius.zero : const Radius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF9EE),
                            ),
                            child: const Icon(
                              LucideIcons.keyRound,
                              color: AppColors.goldPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warmTextDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cập nhật mật khẩu đăng nhập',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warmTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Color(0xFFD1C4B4), size: 18),
                        ],
                      ),
                    ),
                  ),

                  // Action 3: Nhóm của tôi (for Lead role)
                  if (user != null && user.isLead) ...[
                    const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0xFFF0E8DC)),
                    InkWell(
                      onTap: () => context.push('/staff/team'),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFF9EE),
                              ),
                              child: const Icon(
                                LucideIcons.users,
                                color: AppColors.goldPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nhóm của tôi',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warmTextDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Xem danh sách thành viên trong nhóm',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warmTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Color(0xFFD1C4B4), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF5F5),
                  side: const BorderSide(color: Color(0xFFFFD6D6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
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
        Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.warmTextMuted)),
        Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
      ],
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.logOut, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C241E),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có chắc muốn đăng xuất khỏi tài khoản Nhân viên?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.warmTextMuted, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC59B63)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Hủy', style: TextStyle(color: Color(0xFFC59B63), fontWeight: FontWeight.bold, fontSize: 14.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          Navigator.pop(ctx);
                          await authProvider.logout();
                          if (context.mounted) {
                            context.go('/auth/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
