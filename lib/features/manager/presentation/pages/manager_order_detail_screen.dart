import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  void _showCancelBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final provider = context.watch<ManagerOrderDetailProvider>();

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hủy đơn hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lý do hủy đơn',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do hủy đơn hàng...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (provider.cancelError != null) ...[
                const SizedBox(height: 8),
                Text(provider.cancelError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isCancelling ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerOrderDetailProvider>();
    final order = provider.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          order?.orderCode ?? 'Chi tiết đơn hàng',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
              : order == null
                  ? const Center(child: Text('Không tìm thấy đơn hàng.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Order Card
                          Container(
                            padding: const EdgeInsets.all(16),
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
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            Formatters.formatStatus(order.orderStatus),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  order.eventName ?? order.customerName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(Formatters.formatDate(order.eventDate), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(order.location, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tổng giá trị đơn', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    Text(Formatters.formatCurrency(order.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thông tin khách hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.user, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(order.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.phone, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Text(order.customerPhone, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () => _callPhone(order.customerPhone),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(LucideIcons.phone, size: 12, color: Colors.blue.shade700),
                                            const SizedBox(width: 4),
                                            Text('Sao chép SĐT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Payment Links (Deposit & Settlement)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thanh toán', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 12),

                                // Deposit Link Card
                                InkWell(
                                  onTap: () => context.push('/manager/deposits/${widget.orderId}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Đặt cọc', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                              if (provider.latestDeposit != null)
                                                Text(
                                                  '${Formatters.formatCurrency(provider.latestDeposit!.amount)} (${Formatters.formatPaymentStatus(provider.latestDeposit!.status)})',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                )
                                              else
                                                const Text('Chưa có yêu cầu đặt cọc', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Settlement Link Card
                                InkWell(
                                  onTap: () => context.push('/manager/settlements/${widget.orderId}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Quyết toán', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                              if (provider.settlement != null)
                                                Text(
                                                  '${Formatters.formatCurrency(provider.settlement!.finalAmount)} (${Formatters.formatPaymentStatus(provider.settlement!.status)})',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                )
                                              else
                                                const Text('Chưa có hồ sơ quyết toán', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Schedule Plans List
                          const Text('Lịch trình của đơn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),

                          if (provider.plans.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: const Text('Chưa có lịch trình nào.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            )
                          else
                            Column(
                              children: provider.plans.map((plan) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
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
                                          Text(Formatters.formatStatus(plan.status), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          Text(plan.planCode, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(plan.taskName ?? 'Kế hoạch', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text(Formatters.formatTime(plan.startTime), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 20),

                          if (['NEW', 'CONFIRMED', 'IN_PROGRESS'].contains(order.orderStatus))
                            ElevatedButton(
                              onPressed: () => _showCancelBottomSheet(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Hủy đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
