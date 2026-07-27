import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_deposit_provider.dart';
import '../widgets/viet_qr_widget.dart';

class ManagerDepositDetailScreen extends StatefulWidget {
  final String orderId;

  const ManagerDepositDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ManagerDepositDetailScreen> createState() => _ManagerDepositDetailScreenState();
}

class _ManagerDepositDetailScreenState extends State<ManagerDepositDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ManagerDepositProvider>();
      await provider.loadDepositData(widget.orderId);
      _amountController.text = provider.amount;
      _dueDateController.text = provider.dueDate;
      _notesController.text = provider.notes;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerDepositProvider>();
    final order = provider.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tạo QR cọc — ${order?.orderCode ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
              : order == null
                  ? const Center(child: Text('Không tìm thấy dữ liệu đơn hàng.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Dark Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.orderCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                                const SizedBox(height: 4),
                                Text(
                                  order.eventName ?? order.customerName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.customerName} · ${Formatters.formatDate(order.eventDate)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white24, height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tổng giá trị đơn', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                    Text(Formatters.formatCurrency(order.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Đã thu cọc', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                    Text(Formatters.formatCurrency(provider.depositCollected), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade400)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Form cọc
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
                                    const Text('Hồ sơ đặt cọc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    if (provider.currentDeposit != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: provider.isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          Formatters.formatPaymentStatus(provider.currentDeposit!.status),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: provider.isPaid ? Colors.green.shade800 : Colors.amber.shade800),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                const Text('Số tiền đặt cọc (VNĐ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isPaid,
                                  onChanged: (val) => provider.setAmount(val),
                                  decoration: InputDecoration(
                                    hintText: 'Vd: 3500000',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                const Text('Hạn thanh toán cọc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _dueDateController,
                                  keyboardType: TextInputType.datetime,
                                  enabled: !provider.isPaid,
                                  onChanged: (val) => provider.setDueDate(val),
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                const Text('Phương thức thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: provider.paymentMethod == 'cash' ? 'cash' : 'bank_transfer',
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản QR')),
                                    DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                                  ],
                                  onChanged: provider.isPaid ? null : (val) => provider.setPaymentMethod(val ?? 'bank_transfer'),
                                ),

                                const SizedBox(height: 12),

                                const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _notesController,
                                  enabled: !provider.isPaid,
                                  maxLines: 2,
                                  onChanged: (val) => provider.setNotes(val),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập ghi chú cọc...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Số tiền cọc cần thu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                                      Text(
                                        Formatters.formatCurrency(provider.displayAmount),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                      ),
                                    ],
                                  ),
                                ),

                                if (provider.formError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(provider.formError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                                ],

                                const SizedBox(height: 16),

                                if (!provider.isPaid)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: provider.isSaving ? null : () => provider.saveDeposit(widget.orderId),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(44),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: provider.isSaving
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Text('Lưu yêu cầu cọc'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (provider.currentDeposit == null || provider.isConfirming)
                                              ? null
                                              : () => provider.confirmPaid(widget.orderId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            minimumSize: const Size.fromHeight(44),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: provider.isConfirming
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Text('Xác nhận đã nhận cọc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // VietQR Card
                          if (provider.displayAmount > 0)
                            VietQrWidget(
                              amount: provider.displayAmount,
                              addInfo: '${order.orderCode} DAT COC',
                            ),
                        ],
                      ),
                    ),
    );
  }
}
