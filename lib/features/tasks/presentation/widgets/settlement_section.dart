import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/work_task_models.dart';

class SettlementSection extends StatefulWidget {
  final Settlement? existingSettlement;
  final Future<void> Function(File photoFile) onMarkPaid;

  const SettlementSection({
    super.key,
    this.existingSettlement,
    required this.onMarkPaid,
  });

  @override
  State<SettlementSection> createState() => _SettlementSectionState();
}

class _SettlementSectionState extends State<SettlementSection> {
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _photoFile = File(image.path));
    }
  }

  Future<void> _handleMarkPaid() async {
    if (_photoFile == null) {
      setState(() => _error = 'Vui lòng chụp/tải ảnh bằng chứng thanh toán quyết toán.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onMarkPaid(_photoFile!);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.existingSettlement;

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
              Icon(LucideIcons.receipt, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Quyết toán đơn hàng hiện trường',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (s != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildAmountRow('Phụ phí phát sinh', s.additionalFee),
                  _buildAmountRow('Tiền bồi thường hỏng/mất', s.compensation),
                  _buildAmountRow('Giảm giá / Chiết khấu', s.discount, isNegative: true),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG THANH TOÁN QUYẾT TOÁN:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        Formatters.formatCurrency(s.finalAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (s.status == 'PAID' || (s.evidencePhotoUrl != null && s.evidencePhotoUrl!.isNotEmpty)) ...[
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
                  child: Image.network(s.evidencePhotoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
            ] else ...[
              const Text('Thanh toán chuyển khoản / Tiền mặt:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                  label: const Text('Chụp ảnh bằng chứng quyết toán'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
              ],
              const SizedBox(height: 14),
              AppButton(
                text: 'Xác nhận đã thanh toán quyết toán',
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: _handleMarkPaid,
              ),
            ],
          ] else ...[
            const Text('Chưa có thông tin quyết toán cho đơn hàng này.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, num amount, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            '${isNegative ? '-' : ''}${Formatters.formatCurrency(amount)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
