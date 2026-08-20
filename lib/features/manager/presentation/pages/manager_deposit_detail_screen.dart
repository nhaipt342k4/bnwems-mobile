import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  Future<void> _selectDueDate(BuildContext context, ManagerDepositProvider provider) async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(_dueDateController.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.goldPrimary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C241E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = Formatters.toIsoDateOnly(picked);
      _dueDateController.text = formatted;
      provider.setDueDate(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerDepositProvider>();
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
          'Tạo QR cọc — ${order?.orderCode ?? ''}',
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
                  ? const Center(child: Text('Không tìm thấy dữ liệu đơn hàng.', style: TextStyle(color: AppColors.warmTextMuted)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Order Summary Card (Vibrant Warm Gold Gradient)
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
                                Text(
                                  order.orderCode,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE2D5C5)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _cleanTitle(order.orderCode, order.eventName, order.customerName),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${order.customerName} · ${Formatters.formatDate(order.eventDate)}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFD6C5B3)),
                                ),
                                const SizedBox(height: 14),
                                const DepositDottedLine(),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('TỔNG GIÁ TRỊ ĐƠN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB8A594), letterSpacing: 0.5)),
                                    Text(
                                      Formatters.formatCurrency(order.totalAmount),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF3D084)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('ĐÃ THU CỌC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB8A594), letterSpacing: 0.5)),
                                    Text(
                                      Formatters.formatCurrency(provider.depositCollected),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 2. Deposit Form Card
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Hồ sơ đặt cọc',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                    ),
                                    if (provider.currentDeposit != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: provider.isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          Formatters.formatPaymentStatus(provider.currentDeposit!.status),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: provider.isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                const Text('Số tiền đặt cọc (VNĐ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isPaid,
                                  onChanged: (val) => provider.setAmount(val),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: const TextStyle(color: AppColors.warmTextMuted, fontSize: 14),
                                    suffixText: 'đ',
                                    suffixStyle: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                const Text('Hạn thanh toán cọc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _dueDateController,
                                  readOnly: true,
                                  enabled: !provider.isPaid,
                                  onTap: provider.isPaid ? null : () => _selectDueDate(context, provider),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF2C241E)),
                                  decoration: InputDecoration(
                                    hintText: 'Chọn hạn thanh toán cọc',
                                    hintStyle: const TextStyle(color: AppColors.warmTextMuted, fontSize: 13.5),
                                    suffixIcon: const Icon(LucideIcons.calendar, size: 18, color: Color(0xFFC59B63)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                const Text('Phương thức thanh toán', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: provider.paymentMethod == 'cash' ? 'cash' : 'bank_transfer',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF2C241E)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản QR')),
                                    DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                                  ],
                                  onChanged: provider.isPaid ? null : (val) => provider.setPaymentMethod(val ?? 'bank_transfer'),
                                ),

                                const SizedBox(height: 14),

                                const Text('Ghi chú', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _notesController,
                                  enabled: !provider.isPaid,
                                  maxLines: 2,
                                  onChanged: (val) => provider.setNotes(val),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF2C241E)),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập ghi chú cọc...',
                                    hintStyle: const TextStyle(color: AppColors.warmTextMuted, fontSize: 13.5),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFEFE8DC)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Soft Amber/Gold Highlight Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF9EE),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF0DFBD)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Số tiền cọc cần thu', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF5C4E43))),
                                      Text(
                                        Formatters.formatCurrency(provider.displayAmount),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC59B63)),
                                      ),
                                    ],
                                  ),
                                ),

                                if (provider.formError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(provider.formError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                                ],

                                const SizedBox(height: 18),

                                if (!provider.isPaid)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: provider.isSaving ? null : () => provider.saveDeposit(widget.orderId),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(48),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            side: const BorderSide(color: Color(0xFFC59B63)),
                                          ),
                                          child: provider.isSaving
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC59B63)))
                                              : const Text('Lưu yêu cầu cọc', style: TextStyle(color: Color(0xFFC59B63), fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (provider.isConfirming || provider.isSaving)
                                              ? null
                                              : () async {
                                                  if (provider.currentDeposit == null) {
                                                    final ok = await provider.saveDeposit(widget.orderId);
                                                    if (ok) await provider.confirmPaid(widget.orderId);
                                                  } else {
                                                    await provider.confirmPaid(widget.orderId);
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.goldPrimary,
                                            elevation: 0,
                                            minimumSize: const Size.fromHeight(48),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                          const SizedBox(height: 18),

                          // 3. VietQR Card
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

class DepositDottedLine extends StatelessWidget {
  const DepositDottedLine({super.key});

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
