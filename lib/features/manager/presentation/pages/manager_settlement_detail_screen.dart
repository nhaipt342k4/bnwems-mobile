import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final provider = context.watch<ManagerSettlementProvider>();
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
          'Quyết toán — ${order?.orderCode ?? ''}',
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
                                const SettlementDottedLine(),
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

                          // 2. Settlement Form Card
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
                                      'Hồ sơ quyết toán',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                    ),
                                    if (provider.settlement != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: provider.isConfirmed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          Formatters.formatPaymentStatus(provider.settlement!.status),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: provider.isConfirmed ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                const Text('Chi phí phát sinh (VNĐ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _additionalFeeController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isConfirmed,
                                  onChanged: (val) => provider.setAdditionalFee(val),
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

                                const Text('Tiền bồi thường hỏng hóc (VNĐ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _compensationController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isConfirmed,
                                  onChanged: (val) => provider.setCompensation(val),
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

                                const Text('Chiết khấu / Giảm giá (VNĐ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isConfirmed,
                                  onChanged: (val) => provider.setDiscount(val),
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

                                const Text('Ghi chú quyết toán', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _notesController,
                                  enabled: !provider.isConfirmed,
                                  maxLines: 2,
                                  onChanged: (val) => provider.setNotes(val),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF2C241E)),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập ghi chú...',
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

                                // Soft Amber Highlight Card
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
                                      const Text('Số tiền quyết toán cần thu', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF5C4E43))),
                                      Text(
                                        Formatters.formatCurrency(provider.finalAmountToDisplay),
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

                                if (!provider.isConfirmed)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: provider.isSaving ? null : () => provider.saveSettlement(widget.orderId),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(48),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            side: const BorderSide(color: Color(0xFFC59B63)),
                                          ),
                                          child: provider.isSaving
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC59B63)))
                                              : const Text('Lưu hồ sơ', style: TextStyle(color: Color(0xFFC59B63), fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (provider.isConfirming || provider.isSaving)
                                              ? null
                                              : () async {
                                                  if (provider.settlement == null) {
                                                    final ok = await provider.saveSettlement(widget.orderId);
                                                    if (ok) await provider.confirmSettlement(widget.orderId);
                                                  } else {
                                                    await provider.confirmSettlement(widget.orderId);
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
                                              : const Text('Xác nhận đã thu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 3. VietQR Card
                          if (provider.finalAmountToDisplay > 0)
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

class SettlementDottedLine extends StatelessWidget {
  const SettlementDottedLine({super.key});

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
