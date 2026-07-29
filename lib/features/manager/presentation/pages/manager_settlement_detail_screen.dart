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
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Hồ sơ quyết toán cuối kỳ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                      ],
                                    ),
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

                                // Top Summary Box inside card matching mockup
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SỐ TIỀN QUYẾT TOÁN CUỐI',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              Formatters.formatCurrency(provider.finalAmountToDisplay),
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'NGÀY XÁC NHẬN',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              provider.settlement?.paidAt != null && provider.settlement!.paidAt!.isNotEmpty
                                                  ? Formatters.formatDate(provider.settlement!.paidAt!)
                                                  : '—',
                                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PHƯƠNG THỨC',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              provider.paymentMethod == 'cash' ? 'Tiền mặt' : 'Chuyển khoản Ngân hàng',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 3 Inputs in a Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Phụ thu phát sinh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: _additionalFeeController,
                                            keyboardType: TextInputType.number,
                                            enabled: !provider.isConfirmed,
                                            onChanged: (val) => provider.setAdditionalFee(val),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Bồi thường hư hỏng/mất', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: _compensationController,
                                            keyboardType: TextInputType.number,
                                            enabled: !provider.isConfirmed,
                                            onChanged: (val) => provider.setCompensation(val),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Giảm trừ/Ưu đãi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: _discountController,
                                            keyboardType: TextInputType.number,
                                            enabled: !provider.isConfirmed,
                                            onChanged: (val) => provider.setDiscount(val),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                const Text('Phương thức thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: provider.paymentMethod == 'cash' ? 'cash' : 'bank_transfer',
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản Ngân hàng')),
                                    DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                                  ],
                                  onChanged: provider.isConfirmed ? null : (val) => provider.setPaymentMethod(val ?? 'bank_transfer'),
                                ),

                                const SizedBox(height: 12),

                                const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _notesController,
                                  enabled: !provider.isConfirmed,
                                  maxLines: 2,
                                  onChanged: (val) => provider.setNotes(val),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Ước tính cần thu cuối:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade900)),
                                      Text(
                                        Formatters.formatCurrency(provider.finalAmountToDisplay),
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
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
                                        child: ElevatedButton(
                                          onPressed: provider.isSaving ? null : () => provider.saveSettlement(widget.orderId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            minimumSize: const Size.fromHeight(44),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: provider.isSaving
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Text('Cập nhật biên bản quyết toán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: (provider.settlement == null || provider.isConfirming)
                                              ? null
                                              : () => provider.confirmSettlement(widget.orderId),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            minimumSize: const Size.fromHeight(44),
                                            side: const BorderSide(color: AppColors.borderLight),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: provider.isConfirming
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.check, size: 16, color: AppColors.textPrimary),
                                                    SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Xác nhận thu nốt & Quyết toán',
                                                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
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
