import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  static const String appVersion = '1.0.0';

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
                'Bạn có chắc muốn đăng xuất khỏi tài khoản Quản lý?',
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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

            // Profile Hero Card matching Staff Profile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF9EE), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF0DFBD)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gold Circle Avatar Badge
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldPrimary,
                      border: Border.all(color: const Color(0xFFF0DFBD), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldPrimary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        Formatters.getInitial(user?.fullName ?? 'Quản lý'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'Quản lý doanh nghiệp',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: AppColors.warmTextDark,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Badge (Quản lý)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0DFBD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, size: 8, color: AppColors.goldPrimary),
                        SizedBox(width: 6),
                        Text(
                          'Quản lý',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Details Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0E8DC)),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: LucideIcons.user,
                    title: 'Tên đăng nhập',
                    subtitle: user?.username ?? '--',
                  ),
                  const Divider(height: 1, color: Color(0xFFF0E8DC), indent: 56),
                  _buildProfileTile(
                    icon: LucideIcons.phone,
                    title: 'Số điện thoại',
                    subtitle: (user?.phone != null && user!.phone!.isNotEmpty)
                        ? user.phone!
                        : 'Chưa cập nhật',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0E8DC)),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: LucideIcons.userCheck,
                    title: 'Cập nhật hồ sơ cá nhân',
                    onTap: () => context.push('/manager/profile/edit'),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0E8DC), indent: 56),
                  _buildActionTile(
                    icon: LucideIcons.keyRound,
                    title: 'Đổi mật khẩu',
                    onTap: () => context.push('/manager/profile/change-password'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Version Info Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0E8DC)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phiên bản ứng dụng', style: TextStyle(fontSize: 13.5, color: AppColors.warmTextMuted)),
                  Text(appVersion, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Pill Button
            ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
              label: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFDC2626), fontSize: 14.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF5F5),
                foregroundColor: const Color(0xFFDC2626),
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.goldPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.goldPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.warmTextMuted),
          ],
        ),
      ),
    );
  }
}
