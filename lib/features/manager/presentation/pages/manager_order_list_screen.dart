import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_order_list_provider.dart';

class ManagerOrderListScreen extends StatefulWidget {
  final String? initialFilter;

  const ManagerOrderListScreen({super.key, this.initialFilter});

  @override
  State<ManagerOrderListScreen> createState() => _ManagerOrderListScreenState();
}

class _ManagerOrderListScreenState extends State<ManagerOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  QuickFilter? _quickFilterFromParam(String? p) {
    switch (p) {
      case 'upcoming':
        return QuickFilter.upcoming;
      case 'confirmed':
        return QuickFilter.confirmed;
      case 'inProgress':
        return QuickFilter.inProgress;
      case 'completed':
        return QuickFilter.completed;
      case 'all':
        return QuickFilter.all;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerOrderListProvider>();
      final initial = _quickFilterFromParam(widget.initialFilter);
      if (initial != null) provider.setQuickFilter(initial);
      provider.fetchOrders();
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
    final provider = context.watch<ManagerOrderListProvider>();

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ĐƠN HÀNG',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLabel,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Quản lý đơn hàng',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.warmTextDark,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => provider.setSearch(val),
                      style: const TextStyle(fontSize: 14, color: AppColors.warmTextDark),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo mã đơn, tên khách hàng, sự kiện...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
                        prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF8C7B6B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16, color: AppColors.warmTextMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
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
            const SizedBox(height: 14),

            // Order List Content
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                  : provider.errorMessage != null
                      ? Center(
                          child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                        )
                      : provider.filteredOrders.isEmpty
                          ? RefreshIndicator(
                              color: AppColors.goldPrimary,
                              onRefresh: () => provider.fetchOrders(),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  height: 300,
                                  alignment: Alignment.center,
                                  child: const Text('Không tìm thấy đơn hàng nào.', style: TextStyle(color: AppColors.warmTextMuted)),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.goldPrimary,
                              onRefresh: () => provider.fetchOrders(),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                                itemCount: provider.filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = provider.filteredOrders[index];
                                  final cleanScriptTitle = _cleanTitle(order.orderCode, order.eventName, 'Kịch bản sự kiện');

                                  return InkWell(
                                    onTap: () => context.push('/manager/orders/${order.orderId}'),
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 14),
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
                                          // Top Row: Code + Status Badge
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                order.orderCode,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.goldPrimary,
                                                ),
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

                                          // Event Title Row with Icon
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.fileText, size: 14, color: AppColors.warmTextMuted),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  cleanScriptTitle,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.warmTextMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Customer Name
                                          Text(
                                            order.customerName,
                                            style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C241E),
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // Event Date
                                          Text(
                                            Formatters.formatDate(order.eventDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.warmTextMuted,
                                            ),
                                          ),
                                          if (order.location.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.mapPin, size: 13.5, color: AppColors.warmTextMuted),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    order.location,
                                                    style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 14),
                                          const CustomDottedLine(),
                                          const SizedBox(height: 12),

                                          // Bottom Row: Total Amount
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
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(ManagerOrderListProvider provider, QuickFilter filter, String label) {
    final isSelected = provider.quickFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => provider.setQuickFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4A359) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: const Color(0xFFEFE8DC)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4A359).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.warmTextDark,
            ),
          ),
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
