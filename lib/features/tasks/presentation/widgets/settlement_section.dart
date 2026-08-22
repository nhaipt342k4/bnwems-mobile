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
    if (finalAmount > 0) {
      settleLabel = 'Cần thu thêm của khách';
    } else if (finalAmount < 0) {
      settleLabel = 'Phải TRẢ LẠI cho khách';
    } else {
      settleLabel = 'Đã đủ, không thu thêm';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Settlement Form Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
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
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileCheck2, color: Color(0xFF2563EB), size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Hồ sơ quyết toán cuối kỳ',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  if (s != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isPaid ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        Formatters.formatPaymentStatus(s.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (isPaid) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (widget.orderTotalAmount > 0)
                        _buildAmountRow('Giá trị đơn gốc', widget.orderTotalAmount),
                      _buildAmountRow('Phụ phí phát sinh', s.additionalFee),
                      _buildAmountRow('Tiền bồi thường hỏng/mất', s.compensation),
                      _buildAmountRow('Giảm giá / Chiết khấu', s.discount, isNegative: true),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.finalAmount < 0 ? 'ĐÃ TRẢ LẠI KHÁCH:' : 'TỔNG THANH TOÁN:',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Formatters.formatCurrency(s.finalAmount.abs()),
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: s.finalAmount < 0 ? const Color(0xFFC2410C) : const Color(0xFF16A34A)),
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
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle2, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text('ĐÃ THANH TOÁN QUYẾT TOÁN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
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
                      // Top Final Amount Highlight Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: absFinal < 0
                                ? [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)]
                                : absFinal == 0
                                    ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                                    : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: absFinal < 0
                                ? const Color(0xFFFDBA74)
                                : absFinal == 0
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFF59E0B),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (absFinal == 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706)).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(absFinal),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: absFinal < 0 ? const Color(0xFFC2410C) : (absFinal == 0 ? const Color(0xFF15803D) : const Color(0xFF9A3412)),
                                    ),
                                  ),
                                  Text(
                                    settleLabel,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: absFinal < 0 ? const Color(0xFFC2410C) : (absFinal == 0 ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'NGÀY XÁC NHẬN',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s?.paidAt != null && s!.paidAt!.isNotEmpty
                                        ? Formatters.formatDate(s.paidAt!)
                                        : '—',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
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
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _paymentMethod == 'cash' ? LucideIcons.banknote : LucideIcons.building2,
                                          size: 14,
                                          color: const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _paymentMethod == 'cash' ? 'Tiền mặt' : 'Chuyển khoản',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Input 1: Additional Fee
                      const Text('Phụ thu phát sinh (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _additionalFeeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.plusCircle, size: 18, color: Color(0xFF2563EB)),
                          suffixText: 'VNĐ',
                          suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Input 2: Compensation
                      Row(
                        children: [
                          const Text('Bồi thường hư hỏng/mất (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          if (widget.suggestedCompensation > 0 && widget.existingSettlement == null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Text(
                                'Đề xuất',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _compensationController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFD97706)),
                          suffixText: 'VNĐ',
                          suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Input 3: Discount
                      const Text('Giảm trừ / Chiết khấu (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.percent, size: 18, color: Color(0xFF059669)),
                          suffixText: 'VNĐ',
                          suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Payment Method Dropdown
                      const Text('Phương thức thanh toán', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.creditCard, size: 18, color: Color(0xFF4F46E5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản Ngân hàng')),
                          DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                        ],
                        onChanged: (val) => setState(() => _paymentMethod = val ?? 'bank_transfer'),
                      ),

                      const SizedBox(height: 12),

                      // Notes Input
                      const Text('Ghi chú quyết toán', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Nhập ghi chú hoặc lý do phụ thu/chiết khấu...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _paymentMethod == 'bank_transfer' ? 'Ảnh bằng chứng chuyển khoản (tùy chọn)' : 'Ảnh hóa đơn/chứng từ (tùy chọn)',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              backgroundColor: const Color(0xFFEFF6FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: const Color(0xFFD97706).withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
