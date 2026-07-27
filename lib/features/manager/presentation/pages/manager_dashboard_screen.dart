import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerDashboardProvider>().loadDashboardData();
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
        return Colors.amber.shade50;
      case 'COMPLETED':
      case 'PAID':
        return Colors.green.shade50;
      case 'CANCELLED':
      case 'UNPAID':
        return Colors.red.shade50;
      case 'CONFIRMED':
      case 'DEPOSITED':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return Colors.amber.shade800;
      case 'COMPLETED':
      case 'PAID':
        return Colors.green.shade800;
      case 'CANCELLED':
      case 'UNPAID':
        return Colors.red.shade800;
      case 'CONFIRMED':
      case 'DEPOSITED':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<ManagerDashboardProvider>();

    final todayIso = Formatters.toIsoDateOnly(DateTime.now());
    final fullDateStr = Formatters.formatFullDate(todayIso);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                  ? Text(
                      Formatters.getInitial(user?.fullName ?? 'Quản lý'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greetingVi()}, ${user?.fullName ?? 'Quản lý'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fullDateStr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),

              // KPI Stats Grid (2x2)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _buildStatCard(
                    label: 'Đơn sắp diễn ra',
                    value: provider.upcomingOrders.length.toString(),
                    icon: LucideIcons.calendarClock,
                    accentColor: Colors.blue,
                    isLoading: provider.isLoading,
                  ),
                  _buildStatCard(
                    label: 'Công việc hôm nay',
                    value: provider.todayPlans.length.toString(),
                    icon: LucideIcons.listTodo,
                    accentColor: Colors.purple,
                    isLoading: provider.isLoading,
                  ),
                  _buildStatCard(
                    label: 'Đang thực hiện',
                    value: provider.todayPlans.where((p) => p.status == 'IN_PROGRESS').length.toString(),
                    icon: LucideIcons.activity,
                    accentColor: Colors.amber,
                    isLoading: provider.isLoading,
                  ),
                  _buildStatCard(
                    label: 'Mục chờ xử lý',
                    value: provider.pendingSummary.totalCount.toString(),
                    icon: LucideIcons.clock3,
                    accentColor: Colors.pink,
                    isLoading: provider.isLoading,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section Lịch trình hôm nay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch trình hôm nay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/manager/schedule'),
                    child: const Row(
                      children: [
                        Text('Xem tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (provider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (provider.todayPlans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Text('Không có công việc nào hôm nay.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                )
              else
                Column(
                  children: provider.todayPlans.take(5).map((plan) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusBgColor(plan.status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  Formatters.formatStatus(plan.status),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusTextColor(plan.status)),
                                ),
                              ),
                              Text(plan.planCode, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan.taskName ?? 'Kế hoạch',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${plan.eventName ?? plan.orderCode ?? ''} ${plan.customerName != null ? '— ${plan.customerName}' : ''}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${Formatters.formatTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          if (plan.location != null || plan.orderLocation != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    plan.location ?? plan.orderLocation!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (plan.assignees != null && plan.assignees!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: plan.assignees!.map((assignee) {
                                final isLead = assignee.role == 'LEAD';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLead ? Colors.purple.shade50 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.user, size: 11, color: isLead ? Colors.purple.shade700 : Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignee.fullName,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLead ? Colors.purple.shade700 : Colors.blue.shade700),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Section Đơn hàng sắp diễn ra
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đơn hàng sắp diễn ra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/manager/orders'),
                    child: const Row(
                      children: [
                        Text('Xem tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (provider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (provider.upcomingOrders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Text('Không có đơn hàng sắp diễn ra.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                )
              else
                Column(
                  children: provider.upcomingOrders.take(5).map((order) {
                    return InkWell(
                      onTap: () => context.push('/manager/orders/${order.orderId}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.orderCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(order.orderStatus),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        Formatters.formatStatus(order.orderStatus),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusTextColor(order.orderStatus)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(order.paymentStatus),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        Formatters.formatPaymentStatus(order.paymentStatus),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusTextColor(order.paymentStatus)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.eventName ?? order.customerName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.customerName} · ${Formatters.formatDate(order.eventDate)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Formatters.formatCurrency(order.totalAmount),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Section Chờ xử lý Quick Access
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mục chờ xử lý',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/manager/pending'),
                    child: const Row(
                      children: [
                        Text('Xem tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildPendingRow(
                label: 'Đặt cọc chờ xác nhận',
                count: provider.pendingSummary.deposits.length,
                icon: LucideIcons.qrCode,
                accentBg: Colors.green.shade50,
                accentColor: Colors.green.shade700,
                onTap: () => context.go('/manager/pending'),
              ),
              _buildPendingRow(
                label: 'Quyết toán chờ xác nhận',
                count: provider.pendingSummary.settlements.length,
                icon: LucideIcons.receipt,
                accentBg: Colors.purple.shade50,
                accentColor: Colors.purple.shade700,
                onTap: () => context.go('/manager/pending'),
              ),
              _buildPendingRow(
                label: 'Yêu cầu đổi thiết bị',
                count: provider.pendingSummary.changeRequests.length,
                icon: LucideIcons.repeat,
                accentBg: Colors.amber.shade50,
                accentColor: Colors.amber.shade700,
                onTap: () => context.go('/manager/pending'),
              ),
              _buildPendingRow(
                label: 'Báo cáo hoàn kho',
                count: provider.pendingSummary.returnReports.length,
                icon: LucideIcons.packageCheck,
                accentBg: Colors.blue.shade50,
                accentColor: Colors.blue.shade700,
                onTap: () => context.go('/manager/pending'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor accentColor,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accentColor.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            isLoading ? '—' : value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRow({
    required String label,
    required int count,
    required IconData icon,
    required Color accentBg,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('$count mục đang chờ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
