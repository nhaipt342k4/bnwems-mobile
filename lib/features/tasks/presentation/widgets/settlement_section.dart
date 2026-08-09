import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    // Khi giá trị đề xuất thay đổi và settlement chưa tồn tại, tự cập nhật ô bồi thường
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
      // s.finalAmount from backend already has deposit deducted
      base = s.finalAmount - s.additionalFee - s.compensation + s.discount;
    } else if (widget.orderTotalAmount > 0) {
      base = widget.orderTotalAmount - widget.depositCollected;
    }

    final calculated = base + additionalFee + compensation - discount;
    return calculated < 0 ? 0 : calculated;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tải ảnh bằng chứng quyết toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.camera, color: Colors.blue.shade800, size: 20),
              ),
              title: const Text('Chụp ảnh từ máy ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.image, color: Colors.green.shade800, size: 20),
              ),
              title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Dark Card matching Manager Settlement screen
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.orderCode,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                  ),
                  if (s != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.shade900.withValues(alpha: 0.6) : Colors.amber.shade900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Formatters.formatPaymentStatus(s.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green.shade300 : Colors.amber.shade300,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.eventName ?? widget.customerName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.customerName}${widget.eventDate != null ? " · ${Formatters.formatDate(widget.eventDate!)}" : ""}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              if (widget.orderTotalAmount > 0) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng giá trị đơn', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    Text(Formatters.formatCurrency(widget.orderTotalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                if (widget.depositCollected > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đã thu cọc', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      Text(Formatters.formatCurrency(widget.depositCollected), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade400)),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Settlement Form / Detail Container
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
                      const Text(
                        'Hồ sơ quyết toán cuối kỳ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (s != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Formatters.formatPaymentStatus(s.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green.shade800 : Colors.amber.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (isPaid) ...[
                // Paid Settlement Read-only Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (widget.orderTotalAmount > 0)
                        _buildAmountRow('Giá trị đơn gốc', widget.orderTotalAmount),
                      _buildAmountRow('Phụ phí phát sinh', s.additionalFee),
                      _buildAmountRow('Tiền bồi thường hỏng/mất', s.compensation),
                      _buildAmountRow('Giảm giá / Chiết khấu', s.discount, isNegative: true),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'TỔNG THANH TOÁN:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Formatters.formatCurrency(s.finalAmount),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.completedBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle2, color: AppColors.completedText, size: 18),
                      SizedBox(width: 8),
                      Text('ĐÃ THANH TOÁN QUYẾT TOÁN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.completedText)),
                    ],
                  ),
                ),
                if (s.evidencePhotoUrl != null && s.evidencePhotoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                // Unpaid / New Settlement Editable Form matching Mockup exactly
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                    Formatters.formatCurrency(finalAmount),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'NGÀY XÁC NHẬN',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s?.paidAt != null && s!.paidAt!.isNotEmpty
                                        ? Formatters.formatDate(s.paidAt!)
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
                                    _paymentMethod == 'cash' ? 'Tiền mặt' : 'Chuyển khoản Ngân hàng',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3 Inputs Row: Phụ thu phát sinh | Bồi thường hư hỏng/mất | Giảm trừ/Ưu đãi
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
                                Row(
                                  children: [
                                    const Text('Bồi thường hư hỏng/mất', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                                    if (widget.suggestedCompensation > 0 && widget.existingSettlement == null) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Đề xuất',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _compensationController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: widget.suggestedCompensation > 0 && widget.existingSettlement == null
                                            ? Colors.orange.shade400
                                            : Colors.grey.shade400,
                                      ),
                                    ),
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
                        value: _paymentMethod,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản Ngân hàng')),
                          DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                        ],
                        onChanged: (val) => setState(() => _paymentMethod = val ?? 'bank_transfer'),
                      ),

                      const SizedBox(height: 12),

                      const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Live Summary Container matching Manager screen
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ước tính cần thu cuối:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade900)),
                            Text(
                              Formatters.formatCurrency(finalAmount),
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _paymentMethod == 'bank_transfer' ? 'Ảnh bằng chứng chuyển khoản (tùy chọn)' : 'Ảnh hóa đơn/chứng từ (tùy chọn)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      if (_photoFile != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
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
                        OutlinedButton.icon(
                          onPressed: _showImageSourcePickerModal,
                          icon: const Icon(LucideIcons.camera, size: 18),
                          label: const Text('Chụp ảnh hoặc chọn ảnh từ thư viện'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
                      ],

                      const SizedBox(height: 16),

                      // Action Buttons Row matching Mockup
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleCreateOrUpdateSettlement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Cập nhật biên bản quyết toán',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isMarkingPaid ? null : _handleMarkPaid,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                minimumSize: const Size.fromHeight(44),
                                side: const BorderSide(color: AppColors.borderLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isMarkingPaid
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check, size: 16, color: AppColors.textPrimary),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Xác nhận thu nốt & Quyết toán',
                                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
              ],
            ],
          ),
        ),

        // Standalone VietQR Card below Form Container matching Manager Screen
        if ((_paymentMethod == 'bank_transfer' || (s != null && s.paymentMethod == 'bank_transfer')) && !isPaid) ...[
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isNegative ? '-' : ''}${Formatters.formatCurrency(amount)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
