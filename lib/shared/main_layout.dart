import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/notifications/presentation/providers/notification_provider.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/staff/dashboard')) return 0;
    if (location.startsWith('/staff/schedule') || location.startsWith('/staff/attendance') || location.startsWith('/staff/tasks')) return 1;
    if (location.startsWith('/staff/notifications')) return 2;
    if (location.startsWith('/staff/profile') || location.startsWith('/staff/team')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/staff/dashboard');
        break;
      case 1:
        context.go('/staff/schedule');
        break;
      case 2:
        context.go('/staff/notifications');
        break;
      case 3:
        context.go('/staff/profile');
        break;
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required int selectedIndex,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF5EAD8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: badgeCount > 0
                    ? Badge(
                        label: Text('$badgeCount'),
                        child: Icon(
                          icon,
                          color: isSelected ? AppColors.goldPrimary : const Color(0xFF9E846B),
                          size: 22,
                        ),
                      )
                    : Icon(
                        icon,
                        color: isSelected ? AppColors.goldPrimary : const Color(0xFF9E846B),
                        size: 22,
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.goldPrimary : const Color(0xFF9E846B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: LucideIcons.home,
                label: 'Trang chủ',
                selectedIndex: selectedIndex,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: LucideIcons.calendar,
                label: 'Lịch trình',
                selectedIndex: selectedIndex,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: LucideIcons.bell,
                label: 'Thông báo',
                selectedIndex: selectedIndex,
                badgeCount: unreadCount,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: LucideIcons.user,
                label: 'Hồ sơ',
                selectedIndex: selectedIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
