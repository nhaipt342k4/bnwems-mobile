import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final List<File> photoFiles;

  File get primaryPhoto => photoFiles.first;

  SurveyReportSubmitInput({
    required this.area,
    required this.length,
    required this.width,
    required this.entrance,
    this.siteConstraints,
    this.proposedItems,
    this.notes,
    required this.photoFiles,
  });
}

class SurveyReportSection extends StatefulWidget {
  final String? planId;
  final SurveyReport? existingReport;
  final String? planStatus;
  final bool isSubmitted;
  final Future<void> Function(SurveyReportSubmitInput input) onSubmit;

  const SurveyReportSection({
    super.key,
    this.planId,
    this.existingReport,
    this.planStatus,
    this.isSubmitted = false,
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

  final List<File> _photoFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isAlreadySubmitted = false;
  bool _isDraftSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isAlreadySubmitted = widget.isSubmitted || widget.existingReport != null;
    _loadDraft();
  }

  @override
  void didUpdateWidget(covariant SurveyReportSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSubmitted != oldWidget.isSubmitted || widget.existingReport != oldWidget.existingReport) {
      setState(() {
        _isAlreadySubmitted = widget.isSubmitted || widget.existingReport != null;
      });
    }
  }

  Future<void> _loadDraft() async {
    if (widget.planId == null || _isAlreadySubmitted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftStr = prefs.getString('survey_draft_${widget.planId}');
      if (draftStr != null && draftStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(draftStr);
        if (_lengthController.text.isEmpty && data['length'] != null) _lengthController.text = data['length'];
        if (_widthController.text.isEmpty && data['width'] != null) _widthController.text = data['width'];
        if (_entranceController.text.isEmpty && data['entrance'] != null) _entranceController.text = data['entrance'];
        if (_constraintsController.text.isEmpty && data['siteConstraints'] != null) _constraintsController.text = data['siteConstraints'];
        if (_proposedController.text.isEmpty && data['proposedItems'] != null) _proposedController.text = data['proposedItems'];
        if (_notesController.text.isEmpty && data['notes'] != null) _notesController.text = data['notes'];
        _updateArea();
        if (mounted) setState(() => _isDraftSaved = true);
      }
    } catch (_) {}
  }

  Future<void> _handleSaveDraft() async {
    if (widget.planId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'length': _lengthController.text,
        'width': _widthController.text,
        'entrance': _entranceController.text,
        'siteConstraints': _constraintsController.text,
        'proposedItems': _proposedController.text,
        'notes': _notesController.text,
      };
      await prefs.setString('survey_draft_${widget.planId}', jsonEncode(data));
      setState(() => _isDraftSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu bản nháp khảo sát thành công! Bạn vẫn có thể tiếp tục chỉnh sửa.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu bản nháp: $e'), backgroundColor: Colors.red),
      );
    }
  }

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

  void _showImagePickerOptions() {
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
              'Tải ảnh khảo sát mặt bằng',
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
                _pickFromCamera();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.image, color: Colors.green.shade800, size: 20),
              ),
              title: const Text('Chọn nhiều ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        setState(() {
          _photoFiles.add(File(image.path));
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể mở camera trên thiết bị/nền tảng này. Vui lòng chọn ảnh từ thư viện.';
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() {
          _photoFiles.addAll(images.map((img) => File(img.path)));
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể chọn ảnh từ thư viện: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoFiles.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoFiles.isEmpty) {
      setState(() => _error = 'Vui lòng chụp hoặc tải lên ít nhất 1 ảnh bằng chứng khảo sát mặt bằng.');
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
          siteConstraints: _constraintsController.text.trim().isEmpty ? null : _constraintsController.text.trim(),
          proposedItems: _proposedController.text.trim().isEmpty ? null : _proposedController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          photoFiles: List.from(_photoFiles),
        ),
      );
      if (widget.planId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('survey_draft_${widget.planId}');
        } catch (_) {}
      }
      setState(() {
        _isAlreadySubmitted = true;
        _isDraftSaved = false;
      });
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Lập báo cáo khảo sát hiện trường',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isAlreadySubmitted) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'ĐÃ NỘP BÁO CÁO KHẢO SÁT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ),
                ] else if (_isDraftSaved) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      'ĐÃ LƯU BẢN NHÁP',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ],
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
                    readOnly: _isAlreadySubmitted,
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
                    readOnly: _isAlreadySubmitted,
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
              readOnly: _isAlreadySubmitted,
              validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập thông tin lối vào' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Vướng mắc thi công (nếu có)',
              hintText: 'Nền dốc nhẹ, cần gia cố chân giàn...',
              controller: _constraintsController,
              readOnly: _isAlreadySubmitted,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Đề xuất vật tư bổ sung (nếu có)',
              hintText: 'Thêm 4 dây cáp tăng cường...',
              controller: _proposedController,
              readOnly: _isAlreadySubmitted,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Ghi chú',
              hintText: 'Lưu ý khác...',
              controller: _notesController,
              readOnly: _isAlreadySubmitted,
            ),
            const SizedBox(height: 14),

            // Multi Photo Upload Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ảnh chụp mặt bằng khảo sát *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (_photoFiles.isNotEmpty)
                  Text(
                    'Đã chọn ${_photoFiles.length} ảnh',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_photoFiles.isEmpty && !_isAlreadySubmitted) ...[
              InkWell(
                onTap: _showImagePickerOptions,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.camera, color: Colors.blue.shade700, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Chụp ảnh hoặc chọn nhiều ảnh từ thư viện',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hỗ trợ tải lên cùng lúc nhiều ảnh bằng chứng mặt bằng',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_photoFiles.isNotEmpty) ...[
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoFiles.length + (_isAlreadySubmitted ? 0 : 1),
                  itemBuilder: (ctx, index) {
                    if (!_isAlreadySubmitted && index == _photoFiles.length) {
                      // Add More Photos Button Card
                      return GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.plus, color: Colors.blue.shade800, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                'Thêm ảnh',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final file = _photoFiles[index];
                    return Stack(
                      children: [
                        Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (!_isAlreadySubmitted)
                          Positioned(
                            top: 4,
                            right: 14,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
            ],
            const SizedBox(height: 16),

            if (_isAlreadySubmitted)
              AppButton(
                text: 'Đã nộp báo cáo khảo sát',
                isFullWidth: true,
                onPressed: null,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _handleSaveDraft,
                      child: const Text('Lưu bản nháp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Gửi báo cáo',
                      isFullWidth: true,
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ),
                ],
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
