import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/work_task_models.dart';

class FieldPaymentSubmitInput {
  final num amount;
  final String method; // 'cash' | 'bank_transfer'
  final String? note;
  final File? photoFile;

  FieldPaymentSubmitInput({
    required this.amount,
    required this.method,
    this.note,
    this.photoFile,
  });
}

class FieldPaymentSection extends StatefulWidget {
  final FieldPaymentRecord? existingPayment;
  final Future<void> Function(FieldPaymentSubmitInput input) onSubmit;

  const FieldPaymentSection({
    super.key,
    this.existingPayment,
    required this.onSubmit,
  });

  @override
  State<FieldPaymentSection> createState() => _FieldPaymentSectionState();
}

class _FieldPaymentSectionState extends State<FieldPaymentSection> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _method = 'cash'; // 'cash' | 'bank_transfer'

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        setState(() => _photoFile = File(image.path));
      }
    } catch (e) {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (image != null) {
          setState(() => _photoFile = File(image.path));
        }
      } catch (gErr) {
        if (mounted) {
          setState(() => _error = 'Không thể mở camera hoặc thư viện ảnh trên thiết bị này.');
        }
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_method == 'bank_transfer' && _photoFile == null) {
      setState(() => _error = 'Chuyển khoản bắt buộc chụp/tải ảnh bằng chứng chuyển tiền.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final amount = num.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      await widget.onSubmit(
        FieldPaymentSubmitInput(
          amount: amount,
          method: _method,
          note: _noteController.text.trim(),
          photoFile: _photoFile,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.existingPayment != null) {
      final p = widget.existingPayment!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: AppColors.completedText, size: 18),
                SizedBox(width: 8),
                Text(
                  'ĐÃ GHI NHẬN ĐẶT CỌC HẠNG MỤC',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.completedText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Số tiền cọc:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(
                  Formatters.formatCurrency(p.amount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phương thức:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(
                  p.method == 'cash' ? 'Tiền mặt' : 'Chuyển khoản QR',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            if (p.note != null && p.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ghi chú:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      p.note!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
            if (p.evidencePhotoUrl != null && p.evidencePhotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.evidencePhotoUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi nhận thu tiền cọc tại hiện trường',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Số tiền thu cọc (VNĐ) *',
              hintText: '500,000',
              keyboardType: TextInputType.number,
              controller: _amountController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền cọc';
                final numVal = num.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                if (numVal == null || numVal <= 0) return 'Số tiền không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text('Phương thức thanh toán *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Tiền mặt')),
                    selected: _method == 'cash',
                    onSelected: (s) => setState(() => _method = 'cash'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Chuyển khoản QR')),
                    selected: _method == 'bank_transfer',
                    onSelected: (s) => setState(() => _method = 'bank_transfer'),
                  ),
                ),
              ],
            ),

            if (_method == 'bank_transfer') ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin tài khoản công ty:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    SizedBox(height: 4),
                    Text('Ngân hàng: MBBank - Chi nhánh Hà Nội', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    Text('Số tài khoản: 999988889999', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Chủ tài khoản: CÔNG TY BNWEMS', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            AppTextField(
              label: 'Ghi chú thu cọc',
              hintText: 'Thu cọc mặt bằng khảo sát...',
              controller: _noteController,
            ),
            const SizedBox(height: 14),

            Text(
              _method == 'bank_transfer' ? 'Ảnh bằng chứng chuyển khoản *' : 'Ảnh hóa đơn/chứng từ (tùy chọn)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                onPressed: _pickPhoto,
                icon: const Icon(LucideIcons.camera, size: 18),
                label: const Text('Chụp ảnh bằng chứng'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
            ],
            const SizedBox(height: 16),

            AppButton(
              text: 'Xác nhận thu cọc',
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
