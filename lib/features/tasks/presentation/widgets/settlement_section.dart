import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/work_task_models.dart';
import '../../../manager/presentation/widgets/viet_qr_widget.dart';

class SettlementSubmitInput {
  final num additionalFee;
  final num compensation;
  final num discount;
  final String paymentMethod; // 'cash' | 'bank_transfer'
  final String? notes;
  final File? photoFile;

  SettlementSubmitInput({
    required this.additionalFee,
    required this.compensation,
    required this.discount,
    required this.paymentMethod,
    this.notes,
    this.photoFile,
  });
}

class SettlementSection extends StatefulWidget {
  final Settlement? existingSettlement;
  final String orderCode;
  final String? eventName;
  final String customerName;
  final String? eventDate;
  final num orderTotalAmount;
  final num depositCollected;
  final double suggestedCompensation;
  final Future<void> Function(SettlementSubmitInput input) onSubmitSettlement;
  final Future<void> Function(File photoFile) onMarkPaid;

  const SettlementSection({
    super.key,
    this.existingSettlement,
    required this.orderCode,
    this.eventName,
    required this.customerName,
    this.eventDate,
    this.orderTotalAmount = 0,
    this.depositCollected = 0,
    this.suggestedCompensation = 0.0,
    required this.onSubmitSettlement,
    required this.onMarkPaid,
  });

  @override
  State<SettlementSection> createState() => _SettlementSectionState();
}

class _SettlementSectionState extends State<SettlementSection> {
  final _formKey = GlobalKey<FormState>();
  final _additionalFeeController = TextEditingController(text: '0');
  final _compensationController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  String _paymentMethod = 'bank_transfer';

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isMarkingPaid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existingSettlement != null) {
      final s = widget.existingSettlement!;
      _additionalFeeController.text = s.additionalFee == 0 ? '0' : s.additionalFee.toInt().toString();
      _compensationController.text = s.compensation == 0 ? '0' : s.compensation.toInt().toString();
      _discountController.text = s.discount == 0 ? '0' : s.discount.toInt().toString();
      _notesController.text = s.notes ?? '';
      if (s.paymentMethod != null && s.paymentMethod!.isNotEmpty) {
        _paymentMethod = s.paymentMethod == 'cash' ? 'cash' : 'bank_transfer';
      }
    } else if (widget.suggestedCompensation > 0) {
      _compensationController.text = widget.suggestedCompensation.toInt().toString();
    }
    _additionalFeeController.addListener(_onAmountChanged);
    _compensationController.addListener(_onAmountChanged);
    _discountController.addListener(_onAmountChanged);
  }

  @override
  void didUpdateWidget(covariant SettlementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingSettlement == null &&
        widget.suggestedCompensation != oldWidget.suggestedCompensation &&
        widget.suggestedCompensation > 0) {
      _compensationController.text = widget.suggestedCompensation.toInt().toString();
    }
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _additionalFeeController.removeListener(_onAmountChanged);
    _compensationController.removeListener(_onAmountChanged);
    _discountController.removeListener(_onAmountChanged);
    _additionalFeeController.dispose();
    _compensationController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  num get _finalAmountToDisplay {
    if (widget.existingSettlement != null && widget.existingSettlement!.status == 'PAID') {
      return widget.existingSettlement!.finalAmount;
    }

    final additionalFee = num.tryParse(_additionalFeeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final compensation = num.tryParse(_compensationController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final discount = num.tryParse(_discountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    num base = 0;
    if (widget.existingSettlement != null) {
      final s = widget.existingSettlement!;
      base = s.finalAmount - s.additionalFee - s.compensation + s.discount;
    } else if (widget.orderTotalAmount > 0) {
      base = widget.orderTotalAmount - widget.depositCollected;
    }

    return base + additionalFee + compensation - discount;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        setState(() => _photoFile = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể chụp/chọn ảnh từ nguồn này trên thiết bị hiện tại.');
      }
    }
  }

  void _showImageSourcePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tải ảnh bằng chứng quyết toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF7F2EA), shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, color: AppColors.goldPrimary, size: 20),
              ),
              title: const Text('Chụp ảnh từ máy ảnh', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warmTextDark)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            const Divider(height: 1, color: Color(0xFFF0E8DC)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF7F2EA), shape: BoxShape.circle),
                child: const Icon(LucideIcons.image, color: AppColors.goldPrimary, size: 20),
              ),
              title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warmTextDark)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateOrUpdateSettlement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final additionalFee = num.tryParse(_additionalFeeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final compensation = num.tryParse(_compensationController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final discount = num.tryParse(_discountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      await widget.onSubmitSettlement(
        SettlementSubmitInput(
          additionalFee: additionalFee,
          compensation: compensation,
          discount: discount,
          paymentMethod: _paymentMethod,
          notes: _notesController.text.trim(),
          photoFile: _photoFile,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleMarkPaid() async {
    if (_photoFile == null) {
      setState(() => _error = 'Vui lòng chụp ảnh bằng chứng thanh toán quyết toán.');
      return;
    }

    setState(() {
      _isMarkingPaid = true;
      _error = null;
    });

    try {
      await widget.onMarkPaid(_photoFile!);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isMarkingPaid = false;
      });
    } finally {
      if (mounted) setState(() => _isMarkingPaid = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.existingSettlement;
    final finalAmount = _finalAmountToDisplay;
    final isPaid = s != null && s.status == 'PAID';
    final absFinal = finalAmount.abs();
    final String settleLabel;
    final Color settleBg;
    final Color settleFg;
    if (finalAmount > 0) {
      settleLabel = 'Cần thu thêm của khách';
      settleBg = const Color(0xFFFFF9EE);
      settleFg = AppColors.goldLabel;
    } else if (finalAmount < 0) {
      settleLabel = 'Phải TRẢ LẠI cho khách';
      settleBg = const Color(0xFFFFF7ED);
      settleFg = const Color(0xFFC2410C);
    } else {
      settleLabel = 'Đã đủ, không thu thêm';
      settleBg = const Color(0xFFF0FDF4);
      settleFg = const Color(0xFF15803D);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Gold Luxury Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C241E),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                    widget.orderCode,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                  ),
                  if (s != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? const Color(0xFF16A34A).withValues(alpha: 0.2) : AppColors.goldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        Formatters.formatPaymentStatus(s.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? const Color(0xFF4ADE80) : AppColors.goldPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.eventName ?? widget.customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.customerName}${widget.eventDate != null ? " · ${Formatters.formatDate(widget.eventDate!)}" : ""}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFFA89A8B)),
              ),
              if (widget.orderTotalAmount > 0) ...[
                const SizedBox(height: 14),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng giá trị đơn', style: TextStyle(fontSize: 12.5, color: Color(0xFFA89A8B))),
                    Text(Formatters.formatCurrency(widget.orderTotalAmount), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                if (widget.depositCollected > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đã thu cọc', style: TextStyle(fontSize: 12.5, color: Color(0xFFA89A8B))),
                      Text(Formatters.formatCurrency(widget.depositCollected), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Settlement Form Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
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
                        decoration: const BoxDecoration(color: AppColors.goldPrimary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Hồ sơ quyết toán cuối kỳ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                      ),
                    ],
                  ),
                  if (s != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        Formatters.formatPaymentStatus(s.status),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? const Color(0xFF16A34A) : AppColors.goldLabel,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (isPaid) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      if (widget.orderTotalAmount > 0)
                        _buildAmountRow('Giá trị đơn gốc', widget.orderTotalAmount),
                      _buildAmountRow('Phụ phí phát sinh', s.additionalFee),
                      _buildAmountRow('Tiền bồi thường hỏng/mất', s.compensation),
                      _buildAmountRow('Giảm giá / Chiết khấu', s.discount, isNegative: true),
                      const Divider(height: 16, color: Color(0xFFEAD8B7)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.finalAmount < 0 ? 'ĐÃ TRẢ LẠI KHÁCH:' : 'TỔNG THANH TOÁN:',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Formatters.formatCurrency(s.finalAmount.abs()),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: s.finalAmount < 0 ? const Color(0xFFC2410C) : AppColors.goldPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle2, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text('ĐÃ THANH TOÁN QUYẾT TOÁN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
                if (s.evidencePhotoUrl != null && s.evidencePhotoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      s.evidencePhotoUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: settleBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: settleFg.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SỐ TIỀN QUYẾT TOÁN CUỐI',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(absFinal),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: settleFg),
                                  ),
                                  Text(
                                    settleLabel,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: settleFg),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'NGÀY XÁC NHẬN',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s?.paidAt != null && s!.paidAt!.isNotEmpty
                                        ? Formatters.formatDate(s.paidAt!)
                                        : '—',
                                    style: const TextStyle(fontSize: 13, color: AppColors.warmTextDark, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PHƯƠNG THỨC',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _paymentMethod == 'cash' ? 'Tiền mặt' : 'Chuyển khoản Ngân hàng',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text('Phụ thu phát sinh (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _additionalFeeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F2EA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Bồi thường hư hỏng/mất (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                          if (widget.suggestedCompensation > 0 && widget.existingSettlement == null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đề xuất',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.goldLabel),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _compensationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F2EA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Giảm trừ / Chiết khấu (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F2EA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text('Phương thức thanh toán', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F2EA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản Ngân hàng', style: TextStyle(color: AppColors.warmTextDark))),
                          DropdownMenuItem(value: 'cash', child: Text('Tiền mặt', style: TextStyle(color: AppColors.warmTextDark))),
                        ],
                        onChanged: (val) => setState(() => _paymentMethod = val ?? 'bank_transfer'),
                      ),

                      const SizedBox(height: 12),

                      const Text('Ghi chú quyết toán', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF7F2EA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _paymentMethod == 'bank_transfer' ? 'Ảnh bằng chứng chuyển khoản (tùy chọn)' : 'Ảnh hóa đơn/chứng từ (tùy chọn)',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                      ),
                      const SizedBox(height: 8),
                      if (_photoFile != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_photoFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _photoFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _showImageSourcePickerModal,
                            icon: const Icon(LucideIcons.camera, size: 18),
                            label: const Text('Chụp ảnh hoặc chọn từ thư viện'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldPrimary,
                              side: const BorderSide(color: Color(0xFFF0E8DC)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _handleCreateOrUpdateSettlement,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Lưu quyết toán',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isMarkingPaid ? null : _handleMarkPaid,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C241E),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: _isMarkingPaid
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check, size: 16, color: Colors.white),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'Xác nhận thu nốt',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        if ((_paymentMethod == 'bank_transfer' || (s != null && s.paymentMethod == 'bank_transfer')) && !isPaid && finalAmount > 0) ...[
          const SizedBox(height: 16),
          VietQrWidget(
            amount: finalAmount.toDouble(),
            addInfo: '${widget.orderCode} QUYET TOAN',
          ),
        ],
      ],
    );
  }

  Widget _buildAmountRow(String label, num amount, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isNegative ? '-' : ''}${Formatters.formatCurrency(amount)}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
          ),
        ],
      ),
    );
  }
}
