import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_order_list_provider.dart';

class ManagerOrderListScreen extends StatefulWidget {
  const ManagerOrderListScreen({super.key});

  @override
  State<ManagerOrderListScreen> createState() => _ManagerOrderListScreenState();
}

class _ManagerOrderListScreenState extends State<ManagerOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerOrderListProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final provider = context.watch<ManagerOrderListProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search & Filter header section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã đơn, tên khách hàng...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFilterChip(provider, QuickFilter.all, 'Tất cả'),
                      _buildQuickFilterChip(provider, QuickFilter.confirmed, 'Đã xác nhận'),
                      _buildQuickFilterChip(provider, QuickFilter.upcoming, 'Sắp diễn ra'),
                      _buildQuickFilterChip(provider, QuickFilter.inProgress, 'Đang thực hiện'),
                      _buildQuickFilterChip(provider, QuickFilter.completed, 'Hoàn thành'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Order List Content
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(
                        child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                      )
                    : provider.filteredOrders.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () => provider.fetchOrders(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: 300,
                                alignment: Alignment.center,
                                child: const Text('Không tìm thấy đơn hàng nào.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchOrders(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = provider.filteredOrders[index];
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
                                        const SizedBox(height: 4),
                                        Text(
                                          order.location,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(ManagerOrderListProvider provider, QuickFilter filter, String label) {
    final isSelected = provider.quickFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => provider.setQuickFilter(filter),
      ),
    );
  }
}
