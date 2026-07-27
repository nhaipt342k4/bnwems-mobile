import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/work_task_models.dart';

class SurveyReportSubmitInput {
  final double area;
  final double length;
  final double width;
  final String entrance;
  final String? siteConstraints;
  final String? proposedItems;
  final String? notes;
  final File photoFile;

  SurveyReportSubmitInput({
    required this.area,
    required this.length,
    required this.width,
    required this.entrance,
    this.siteConstraints,
    this.proposedItems,
    this.notes,
    required this.photoFile,
  });
}

class SurveyReportSection extends StatefulWidget {
  final SurveyReport? existingReport;
  final String? planStatus;
  final Future<void> Function(SurveyReportSubmitInput input) onSubmit;

  const SurveyReportSection({
    super.key,
    this.existingReport,
    this.planStatus,
    required this.onSubmit,
  });

  @override
  State<SurveyReportSection> createState() => _SurveyReportSectionState();
}

class _SurveyReportSectionState extends State<SurveyReportSection> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _entranceController = TextEditingController();
  final _constraintsController = TextEditingController();
  final _proposedController = TextEditingController();
  final _notesController = TextEditingController();

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _areaController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _entranceController.dispose();
    _constraintsController.dispose();
    _proposedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _photoFile = File(image.path));
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoFile == null) {
      setState(() => _error = 'Vui lòng chụp ảnh bằng chứng khảo sát mặt bằng.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        SurveyReportSubmitInput(
          area: double.parse(_areaController.text),
          length: double.parse(_lengthController.text),
          width: double.parse(_widthController.text),
          entrance: _entranceController.text.trim(),
          siteConstraints: _constraintsController.text.trim(),
          proposedItems: _proposedController.text.trim(),
          notes: _notesController.text.trim(),
          photoFile: _photoFile!,
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
    if (widget.existingReport != null) {
      final report = widget.existingReport!;
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
                Icon(LucideIcons.fileCheck2, color: AppColors.completedText, size: 18),
                SizedBox(width: 8),
                Text(
                  'BÁO CÁO KHẢO SÁT ĐÃ GỬI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.completedText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Diện tích', '${report.area} m² (${report.length}m x ${report.width}m)'),
            _buildDetailRow('Lối vào', report.entrance),
            if (report.siteConstraints != null && report.siteConstraints!.isNotEmpty)
              _buildDetailRow('Vướng mắc', report.siteConstraints!),
            if (report.proposedItems != null && report.proposedItems!.isNotEmpty)
              _buildDetailRow('Đề xuất', report.proposedItems!),
            if (report.notes != null && report.notes!.isNotEmpty)
              _buildDetailRow('Ghi chú', report.notes!),
            if (report.evidencePhotoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.evidencePhotoUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Read-only notice if plan is already finished/cancelled and no report exists
    if (widget.planStatus == 'COMPLETED' || widget.planStatus == 'CANCELLED') {
      final isCompleted = widget.planStatus == 'COMPLETED';
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
            Row(
              children: [
                Icon(
                  isCompleted ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  color: isCompleted ? AppColors.completedText : AppColors.cancelledText,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'BÁO CÁO KHẢO SÁT HỆ THỐNG' : 'KẾ HOẠCH ĐÃ HỦY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.completedText : AppColors.cancelledText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Kế hoạch khảo sát đã hoàn thành. Không có dữ liệu báo cáo khảo sát ghi nhận.'
                  : 'Kế hoạch đã bị hủy.',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
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
              'Lập báo cáo khảo sát hiện trường',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Chiều dài (m)',
                    hintText: '10',
                    keyboardType: TextInputType.number,
                    controller: _lengthController,
                    validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                    onChanged: (v) => _updateArea(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    label: 'Chiều rộng (m)',
                    hintText: '5',
                    keyboardType: TextInputType.number,
                    controller: _widthController,
                    validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                    onChanged: (v) => _updateArea(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    label: 'Diện tích (m²)',
                    hintText: '50',
                    readOnly: true,
                    controller: _areaController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Lối vào mặt bằng *',
              hintText: 'Rộng 3m, xe 2.5 tấn vào tận nơi',
              controller: _entranceController,
              validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập thông tin lối vào' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Vướng mắc thi công (nếu có)',
              hintText: 'Nền dốc nhẹ, cần gia cố chân giàn...',
              controller: _constraintsController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Đề xuất vật tư bổ sung (nếu có)',
              hintText: 'Thêm 4 dây cáp tăng cường...',
              controller: _proposedController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Ghi chú',
              hintText: 'Lưu ý khác...',
              controller: _notesController,
            ),
            const SizedBox(height: 14),

            const Text(
              'Ảnh chụp mặt bằng khảo sát *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                label: const Text('Chụp ảnh mặt bằng'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
            ],
            const SizedBox(height: 16),

            AppButton(
              text: 'Gửi báo cáo khảo sát',
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  void _updateArea() {
    final l = double.tryParse(_lengthController.text) ?? 0;
    final w = double.tryParse(_widthController.text) ?? 0;
    _areaController.text = (l * w).toStringAsFixed(1);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
