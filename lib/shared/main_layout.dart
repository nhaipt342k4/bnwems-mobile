import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.clock),
              label: 'Lịch trình',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(LucideIcons.bell),
              ),
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
