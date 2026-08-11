import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class ManagerBottomNav extends StatelessWidget {
  const ManagerBottomNav({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/manager/dashboard')) {
      return 0;
    }
    if (location.startsWith('/manager/schedule')) {
      return 1;
    }
    if (location.startsWith('/manager/orders') ||
        location.startsWith('/manager/deposits') ||
        location.startsWith('/manager/settlements')) {
      return 2;
    }
    if (location.startsWith('/manager/pending') ||
        location.startsWith('/manager/change-requests') ||
        location.startsWith('/manager/returns')) {
      return 3;
    }
    if (location.startsWith('/manager/profile')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/manager/dashboard');
        break;
      case 1:
        context.go('/manager/schedule');
        break;
      case 2:
        context.go('/manager/orders');
        break;
      case 3:
        context.go('/manager/pending');
        break;
      case 4:
        context.go('/manager/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Container(
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendarDays),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.clipboardList),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.clock3),
            label: 'Chờ xử lý',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.userCircle),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
