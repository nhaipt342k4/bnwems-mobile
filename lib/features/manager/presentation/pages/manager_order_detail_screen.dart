import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_order_detail_provider.dart';

class ManagerOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const ManagerOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ManagerOrderDetailScreen> createState() => _ManagerOrderDetailScreenState();
}

class _ManagerOrderDetailScreenState extends State<ManagerOrderDetailScreen> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerOrderDetailProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
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

  void _showCancelBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final provider = context.watch<ManagerOrderDetailProvider>();

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hủy đơn hàng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C241E), fontFamily: 'serif'),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.warmTextMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Lý do hủy đơn',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C241E)),
                decoration: InputDecoration(
                  hintText: 'Nhập lý do hủy đơn hàng...',
                  hintStyle: const TextStyle(color: AppColors.warmTextMuted, fontSize: 13.5),
                  filled: true,
                  fillColor: const Color(0xFFFAF6F0),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                  ),
                ),
              ),
              if (provider.cancelError != null) ...[
                const SizedBox(height: 8),
                Text(provider.cancelError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isCancelling ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Color(0xFFEFE8DC)),
                      ),
                      child: const Text('Đóng', style: TextStyle(color: Color(0xFF2C241E), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.isCancelling
                          ? null
                          : () async {
                              final navigator = Navigator.of(ctx);
                              final success = await context.read<ManagerOrderDetailProvider>().cancelOrder(
                                    widget.orderId,
                                    _reasonController.text,
                                  );
                              if (success && navigator.canPop()) {
                                navigator.pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: provider.isCancelling
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Xác nhận hủy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _callPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chép số điện thoại $phone vào khay nhớ tạm'),
        backgroundColor: AppColors.goldPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
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
    final provider = context.watch<ManagerOrderDetailProvider>();
    final order = provider.order;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF2C241E)),
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          order?.orderCode ?? 'Chi tiết đơn hàng',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C241E),
            fontFamily: 'serif',
          ),
        ),
        centerTitle: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))))
              : order == null
                  ? const Center(child: Text('Không tìm thấy đơn hàng.', style: TextStyle(color: AppColors.warmTextMuted)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Hero Order Header Card (Vibrant Warm Gold Gradient)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC59B63), Color(0xFFA87E46)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC59B63).withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
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
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF7EEDD)),
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
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusTextColor(order.orderStatus),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _cleanTitle(order.orderCode, order.eventName, order.customerName),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 14, color: Color(0xFFD6C5B3)),
                                    const SizedBox(width: 6),
                                    Text(
                                      Formatters.formatDate(order.eventDate),
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFD6C5B3)),
                                    ),
                                  ],
                                ),
                                if (order.location.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFFD6C5B3)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          order.location,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFFD6C5B3)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const DetailDottedLine(),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TỔNG GIÁ TRỊ ĐƠN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB8A594),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(order.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFDE68A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 2. Customer Info Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
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
                                const Text(
                                  'Thông tin khách hàng',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFAF6F0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.user, size: 16, color: Color(0xFFC59B63)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        order.customerName,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFAF6F0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.phone, size: 16, color: Color(0xFFC59B63)),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          order.customerPhone,
                                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Color(0xFF2C241E)),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () => _callPhone(order.customerPhone),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAF6F0),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFEFE8DC)),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(LucideIcons.copy, size: 13, color: Color(0xFFC59B63)),
                                            SizedBox(width: 5),
                                            Text(
                                              'Sao chép SĐT',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC59B63)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 3. Payment Links (Deposit & Settlement)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
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
                                const Text(
                                  'Thanh toán',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                ),
                                const SizedBox(height: 14),

                                // Deposit Link Row
                                InkWell(
                                  onTap: () => context.push('/manager/deposits/${widget.orderId}'),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF6F0),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDCFCE7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.qrCode, size: 18, color: Color(0xFF16A34A)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Đặt cọc', style: TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                                              const SizedBox(height: 2),
                                              if (provider.latestDeposit != null)
                                                Text(
                                                  '${Formatters.formatCurrency(provider.latestDeposit!.amount)} (${Formatters.formatPaymentStatus(provider.latestDeposit!.status)})',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                                )
                                              else
                                                const Text('Chưa có yêu cầu đặt cọc', style: TextStyle(fontSize: 13, color: AppColors.warmTextMuted)),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFC4B5A5)),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Settlement Link Row
                                InkWell(
                                  onTap: () => context.push('/manager/settlements/${widget.orderId}'),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF6F0),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF3E8FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.receipt, size: 18, color: Color(0xFF9333EA)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Quyết toán', style: TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                                              const SizedBox(height: 2),
                                              if (provider.settlement != null)
                                                Text(
                                                  '${Formatters.formatCurrency(provider.settlement!.finalAmount)} (${Formatters.formatPaymentStatus(provider.settlement!.status)})',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                                )
                                              else
                                                const Text('Chưa có hồ sơ quyết toán', style: TextStyle(fontSize: 13, color: AppColors.warmTextMuted)),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFC4B5A5)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 4. Schedule Plans List
                          const Text(
                            'Lịch trình của đơn',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                          ),
                          const SizedBox(height: 10),

                          if (provider.plans.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
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
                              child: const Text('Chưa có lịch trình nào.', style: TextStyle(color: AppColors.warmTextMuted, fontSize: 13)),
                            )
                          else
                            Column(
                              children: provider.plans.map((plan) {
                                return InkWell(
                                  onTap: () {
                                    if (plan.planId.isNotEmpty) context.push('/manager/plans/${plan.planId}');
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
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
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(plan.planCode, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusBgColor(plan.status),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                Formatters.formatStatus(plan.status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusTextColor(plan.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                plan.taskName ?? 'Kế hoạch',
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                              ),
                                            ),
                                            const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFC4B5A5)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(Formatters.formatTime(plan.startTime), style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 24),

                          // 5. Cancel Button
                          if (['NEW', 'CONFIRMED', 'IN_PROGRESS'].contains(order.orderStatus))
                            InkWell(
                              onTap: () => _showCancelBottomSheet(context),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.xCircle, size: 18, color: Color(0xFFDC2626)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hủy đơn hàng',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }
}

class DetailDottedLine extends StatelessWidget {
  const DetailDottedLine({super.key});

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
                decoration: BoxDecoration(color: Color(0xFF6E5644)),
              ),
            );
          }),
        );
      },
    );
  }
}
