import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_settlement_provider.dart';
import '../widgets/viet_qr_widget.dart';

class ManagerSettlementDetailScreen extends StatefulWidget {
  final String orderId;

  const ManagerSettlementDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ManagerSettlementDetailScreen> createState() => _ManagerSettlementDetailScreenState();
}

class _ManagerSettlementDetailScreenState extends State<ManagerSettlementDetailScreen> {
  final TextEditingController _additionalFeeController = TextEditingController();
  final TextEditingController _compensationController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ManagerSettlementProvider>();
      await provider.loadSettlementData(widget.orderId);
      _additionalFeeController.text = provider.additionalFee;
      _compensationController.text = provider.compensation;
      _discountController.text = provider.discount;
      _notesController.text = provider.notes;
    });
  }

  @override
  void dispose() {
    _additionalFeeController.dispose();
    _compensationController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerSettlementProvider>();
    final order = provider.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quyết toán — ${order?.orderCode ?? ''}',
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

                          // Settlement Form
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
                                    const Text('Hồ sơ quyết toán cuối kỳ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    if (provider.settlement != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: provider.isConfirmed ? Colors.green.shade50 : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          Formatters.formatPaymentStatus(provider.settlement!.status),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: provider.isConfirmed ? Colors.green.shade800 : Colors.amber.shade800),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                const Text('Phụ phí phát sinh (VNĐ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _additionalFeeController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isConfirmed,
                                  onChanged: (val) => provider.setAdditionalFee(val),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                const Text('Đền bù hỏng/mất (VNĐ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _compensationController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isConfirmed,
                                  onChanged: (val) => provider.setCompensation(val),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                const Text('Giảm giá (VNĐ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isConfirmed,
                                  onChanged: (val) => provider.setDiscount(val),
                                  decoration: InputDecoration(
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
                                  onChanged: provider.isConfirmed ? null : (val) => provider.setPaymentMethod(val ?? 'bank_transfer'),
                                ),

                                const SizedBox(height: 12),

                                const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _notesController,
                                  enabled: !provider.isConfirmed,
                                  maxLines: 2,
                                  onChanged: (val) => provider.setNotes(val),
                                  decoration: InputDecoration(
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
                                      Text('Ước tính cần thu cuối', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                                      Text(
                                        Formatters.formatCurrency(provider.finalAmountToDisplay),
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

                                if (!provider.isConfirmed)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: provider.isSaving ? null : () => provider.saveSettlement(widget.orderId),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(44),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: provider.isSaving
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Text('Lưu quyết toán'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (provider.settlement == null || provider.isConfirming)
                                              ? null
                                              : () => provider.confirmSettlement(widget.orderId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            minimumSize: const Size.fromHeight(44),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: provider.isConfirming
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // VietQR Card
                          if (!provider.isConfirmed && provider.finalAmountToDisplay > 0)
                            VietQrWidget(
                              amount: provider.finalAmountToDisplay,
                              addInfo: '${order.orderCode} QUYET TOAN',
                            ),
                        ],
                      ),
                    ),
    );
  }
}
