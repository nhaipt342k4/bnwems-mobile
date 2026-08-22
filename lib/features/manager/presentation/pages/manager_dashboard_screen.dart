import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/manager_dashboard_provider.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    FcmService().initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerDashboardProvider>().loadDashboardData();
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  String _greetingVi() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return const Color(0xFFFEF3C7);
      case 'COMPLETED':
      case 'PAID':
        return const Color(0xFFDCFCE7);
      case 'CANCELLED':
      case 'UNPAID':
        return const Color(0xFFFEE2E2);
      case 'CONFIRMED':
      case 'DEPOSITED':
        return const Color(0xFFE0F2FE);
      case 'NEW':
      case 'NEW_ORDER':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return const Color(0xFFD97706);
      case 'COMPLETED':
      case 'PAID':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
      case 'UNPAID':
        return const Color(0xFFDC2626);
      case 'CONFIRMED':
      case 'DEPOSITED':
        return const Color(0xFF0284C7);
      case 'NEW':
      case 'NEW_ORDER':
        return const Color(0xFF475569);
      default:
        return const Color(0xFF4B5563);
    }
  }

  String _cleanTitle(String? orderCode, String? rawName, String fallback) {
    final code = (orderCode ?? '').trim();
    var name = (rawName ?? fallback).trim();
    if (code.isNotEmpty) {
      name = name.replaceAll(RegExp(r'\s*[-·]\s*' + RegExp.escape(code), caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'^' + RegExp.escape(code) + r'\s*[-·]\s*', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\b' + RegExp.escape(code) + r'\b', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
      name = name.replaceAll(RegExp(r'^[-·\s]+|[-·\s]+$'), '').trim();
    }
    return name.isNotEmpty ? name : 'Kịch bản sự kiện';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<ManagerDashboardProvider>();

    final todayIso = Formatters.toIsoDateOnly(DateTime.now());
    final fullDateStr = Formatters.formatFullDate(todayIso);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.goldPrimary,
          onRefresh: () => provider.loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Avatar + Greeting + Bell)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC59B63),
                      ),
                      child: Center(
                        child: Text(
                          Formatters.getInitial(user?.fullName ?? 'Quản lý'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greetingVi()}, ${user?.fullName ?? 'Quản lý'}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C241E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullDateStr,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.warmTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<NotificationProvider>(
                      builder: (context, notifProvider, _) {
                        final unreadCount = notifProvider.unreadCount;
                        return Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => context.push('/manager/notifications'),
                                icon: const Icon(
                                  LucideIcons.bell,
                                  color: Color(0xFF2C241E),
                                  size: 20,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // KPI Stats Grid (2x2)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    _buildStatCard(
                      label: 'Đơn sắp diễn ra',
                      value: provider.upcomingOrders.length.toString(),
                      icon: LucideIcons.calendar,
                      badgeBg: const Color(0xFFEBF5FF),
                      iconColor: const Color(0xFF3B82F6),
                      isLoading: provider.isLoading,
                    ),
                    _buildStatCard(
                      label: 'Công việc hôm nay',
                      value: provider.todayPlans.length.toString(),
                      icon: LucideIcons.listCheck,
                      badgeBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      isLoading: provider.isLoading,
                    ),
                    _buildStatCard(
                      label: 'Đang thực hiện',
                      value: provider.todayPlans.where((p) => p.status == 'IN_PROGRESS').length.toString(),
                      icon: LucideIcons.activity,
                      badgeBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      isLoading: provider.isLoading,
                    ),
                    _buildStatCard(
                      label: 'Mục chờ xử lý',
                      value: provider.pendingSummary.totalCount.toString(),
                      icon: LucideIcons.clock,
                      badgeBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      isLoading: provider.isLoading,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section Đơn hàng sắp diễn ra
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đơn hàng sắp diễn ra',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C241E),
                        fontFamily: 'serif',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/manager/orders?filter=upcoming'),
                      child: const Row(
                        children: [
                          Text('Xem tất cả', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF9E7743))),
                          Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF9E7743)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (provider.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.goldPrimary)))
                else if (provider.upcomingOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Không có đơn hàng sắp diễn ra.', style: TextStyle(color: AppColors.warmTextMuted, fontSize: 13)),
                  )
                else
                  Column(
                    children: provider.upcomingOrders.take(5).map((order) {
                      return InkWell(
                        onTap: () => context.push('/manager/orders/${order.orderId}'),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEFE8DC)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderCode,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusBgColor(order.orderStatus),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      Formatters.formatStatus(order.orderStatus),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusTextColor(order.orderStatus),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _cleanTitle(order.orderCode, order.eventName, order.customerName),
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C241E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.customerName} · ${Formatters.formatDate(order.eventDate)}',
                                style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
                              ),
                              const SizedBox(height: 12),
                              const CustomDottedLine(),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TỔNG TIỀN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warmTextMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(order.totalAmount),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.goldPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // Section Mục chờ xử lý
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mục chờ xử lý',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C241E),
                        fontFamily: 'serif',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/manager/pending'),
                      child: const Row(
                        children: [
                          Text('Xem tất cả', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFC59B63))),
                          Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFC59B63)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card Container holding all 5 pending rows matching mockup
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildPendingRow(
                        label: 'Đặt cọc chờ xác nhận',
                        count: provider.pendingSummary.deposits.length,
                        icon: LucideIcons.qrCode,
                        badgeBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        onTap: () => context.go('/manager/pending'),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0E8DC), indent: 64),
                      _buildPendingRow(
                        label: 'Quyết toán chờ xác nhận',
                        count: provider.pendingSummary.settlements.length,
                        icon: LucideIcons.receipt,
                        badgeBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        onTap: () => context.go('/manager/pending'),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0E8DC), indent: 64),
                      _buildPendingRow(
                        label: 'Báo cáo hoàn kho',
                        count: provider.pendingSummary.returnReports.length,
                        icon: LucideIcons.packageCheck,
                        badgeBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        onTap: () => context.go('/manager/pending'),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0E8DC), indent: 64),
                      _buildPendingRow(
                        label: 'Khảo sát chờ xác nhận',
                        count: provider.pendingSummary.surveys.length,
                        icon: LucideIcons.clipboardList,
                        badgeBg: const Color(0xFFE6FFFA),
                        iconColor: const Color(0xFF0D9488),
                        onTap: () => context.go('/manager/pending'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color badgeBg,
    required Color iconColor,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoading ? '—' : value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C241E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRow({
    required String label,
    required int count,
    required IconData icon,
    required Color badgeBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count mục đang chờ',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFC4B5A5)),
          ],
        ),
      ),
    );
  }
}

class CustomDottedLine extends StatelessWidget {
  const CustomDottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF9E876B)),
              ),
            );
          }),
        );
      },
    );
  }
}
