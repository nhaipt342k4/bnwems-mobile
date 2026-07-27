import 'package:flutter/material.dart';
import 'manager_bottom_nav.dart';

class ManagerLayout extends StatelessWidget {
  final Widget child;

  const ManagerLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const ManagerBottomNav(),
    );
  }
}
