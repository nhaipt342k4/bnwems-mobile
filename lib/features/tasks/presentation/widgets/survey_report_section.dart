import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/quotation_item_model.dart';
import '../../data/models/work_task_models.dart';
import 'equipment_picker_sheet.dart';

class SurveyReportSubmitInput {
  final double area;
  final double length;
  final double width;
  final String entrance;
  final String? siteConstraints;
  final String? proposedItems;
  final String? notes;
  final List<File> photoFiles;
  final List<QuotationItemInput> quotationItems;

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
    this.quotationItems = const [],
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
  final List<QuotationItemInput> _quotationItems = [];
  final ImagePicker _picker = ImagePicker();
  
  bool _isSubmitting = false;
  bool _isAlreadySubmitted = false;
  bool _isDraftSaved = false;
  String? _error;
  SurveyReport? _submittedReport;
  List<QuotationItemInput> _savedQuotationItems = [];

  @override
  void initState() {
    super.initState();
    _isAlreadySubmitted = widget.isSubmitted || widget.existingReport != null;
    _loadDraft();
    _loadSavedQuotationItems();
  }

  @override
  void didUpdateWidget(covariant SurveyReportSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSubmitted != oldWidget.isSubmitted || widget.existingReport != oldWidget.existingReport) {
      setState(() {
        _isAlreadySubmitted = widget.isSubmitted || widget.existingReport != null;
      });
      _loadSavedQuotationItems();
    }
  }

  Future<void> _loadSavedQuotationItems() async {
    if (widget.planId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('survey_quotation_${widget.planId}');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedStr);
        if (mounted) {
          setState(() {
            _savedQuotationItems = list
                .map((i) => QuotationItemInput.fromJson(i as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (_) {}
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
        
        if (data['quotationItems'] is List) {
          _quotationItems.clear();
          for (final item in data['quotationItems']) {
            _quotationItems.add(QuotationItemInput.fromJson(item as Map<String, dynamic>));
          }
        }
        
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
        'quotationItems': _quotationItems.map((item) => item.toJson()).toList(),
      };
      await prefs.setString('survey_draft_${widget.planId}', jsonEncode(data));
      setState(() => _isDraftSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu bản nháp khảo sát & báo giá thành công!'),
            backgroundColor: AppColors.goldPrimary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu bản nháp: $e'), backgroundColor: Colors.red),
        );
      }
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

  double get _subtotalAmount => _quotationItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _totalDiscountAmount => _quotationItems.fold(0.0, (sum, item) => sum + item.totalDiscount);
  double get _totalQuotationAmount => _quotationItems.fold(0.0, (sum, item) => sum + item.totalAmount);

  void _addPresetItem(CatalogItemPreset preset) {
    setState(() {
      final existingIndex = _quotationItems.indexWhere((i) => i.name.toLowerCase() == preset.name.toLowerCase());
      if (existingIndex >= 0) {
        _quotationItems[existingIndex].quantity += 1;
      } else {
        _quotationItems.add(
          QuotationItemInput(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            itemId: preset.itemId,
            name: preset.name,
            category: preset.category,
            unit: preset.unit,
            quantity: 1,
            unitPrice: preset.defaultPrice,
          ),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${preset.name}" vào báo giá'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.goldPrimary,
      ),
    );
  }

  void _showCustomItemDialog() {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Thiết bị & Dịch vụ');
    final unitCtrl = TextEditingController(text: 'Cái');
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final discountCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(LucideIcons.plusCircle, color: AppColors.goldPrimary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Thêm hạng mục tùy chỉnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Tên hạng mục *', hintText: 'Ví dụ: Thiết kế mẫu 3D...', controller: nameCtrl),
              const SizedBox(height: 10),
              AppTextField(label: 'Phân loại', hintText: 'Máy quay, Âm thanh, Sân khấu...', controller: categoryCtrl),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Đơn vị tính (ĐVT)', hintText: 'Cái, Bộ, m²', controller: unitCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: AppTextField(label: 'Số lượng', hintText: '1', keyboardType: TextInputType.number, controller: qtyCtrl)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Đơn giá (đ) *', hintText: '500000', keyboardType: TextInputType.number, controller: priceCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: AppTextField(label: 'Giảm giá/Item (đ)', hintText: '0', keyboardType: TextInputType.number, controller: discountCtrl)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.warmTextMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final discount = double.tryParse(discountCtrl.text) ?? 0.0;

              setState(() {
                _quotationItems.add(
                  QuotationItemInput(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    category: categoryCtrl.text.trim().isEmpty ? 'Khác' : categoryCtrl.text.trim(),
                    unit: unitCtrl.text.trim().isEmpty ? 'Cái' : unitCtrl.text.trim(),
                    quantity: qty < 1 ? 1 : qty,
                    unitPrice: price,
                    discountPerItem: discount,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Thêm vào báo giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
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
              'Tải ảnh khảo sát mặt bằng',
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
                _pickFromCamera();
              },
            ),
            const Divider(height: 1, color: Color(0xFFF0E8DC)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF7F2EA), shape: BoxShape.circle),
                child: const Icon(LucideIcons.image, color: AppColors.goldPrimary, size: 20),
              ),
              title: const Text('Chọn nhiều ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warmTextDark)),
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
          _error = 'Không thể mở camera trên thiết bị này. Vui lòng chọn ảnh từ thư viện.';
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
          quotationItems: List.from(_quotationItems),
        ),
      );
      if (widget.planId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('survey_draft_${widget.planId}');
          await prefs.setString(
            'survey_quotation_${widget.planId}',
            jsonEncode(_quotationItems.map((item) => item.toJson()).toList()),
          );
        } catch (_) {}
      }
      setState(() {
        _isAlreadySubmitted = true;
        _isDraftSaved = false;
        _savedQuotationItems = List.from(_quotationItems);
        _submittedReport = SurveyReport(
          submittedAt: Formatters.formatDateTime(DateTime.now().toIso8601String()),
          area: double.tryParse(_areaController.text) ?? 0.0,
          length: double.tryParse(_lengthController.text) ?? 0.0,
          width: double.tryParse(_widthController.text) ?? 0.0,
          entrance: _entranceController.text.trim(),
          siteConstraints: _constraintsController.text.trim().isEmpty ? null : _constraintsController.text.trim(),
          proposedItems: _proposedController.text.trim().isEmpty ? null : _proposedController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          evidencePhotoUrls: _photoFiles.map((f) => f.path).toList(),
          quotationItems: List.from(_quotationItems),
        );
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
    final report = widget.existingReport ?? _submittedReport;
    if (report != null) {
      final effectiveQuotationItems = report.quotationItems.isNotEmpty
          ? report.quotationItems
          : (_savedQuotationItems.isNotEmpty ? _savedQuotationItems : _quotationItems);
      final totalQuotationAmount = effectiveQuotationItems.fold(0.0, (sum, item) => sum + item.totalAmount);

      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFF3EBE0), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'BÁO CÁO KHẢO SÁT ĐÃ GỬI',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (report.submittedAt.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        Formatters.formatDateTime(report.submittedAt),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Metric Grid: Area & Entrance
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.ruler, size: 15, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text('Diện tích', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${report.area} m²',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${report.length}m × ${report.width}m',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.doorOpen, size: 15, color: Color(0xFF4F46E5)),
                            SizedBox(width: 6),
                            Text('Lối vào', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.entrance.isEmpty ? 'Thuận tiện' : report.entrance,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if ((report.siteConstraints != null && report.siteConstraints!.isNotEmpty) ||
                (report.proposedItems != null && report.proposedItems!.isNotEmpty) ||
                (report.notes != null && report.notes!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  if (report.siteConstraints != null && report.siteConstraints!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(text: 'Vướng mắc: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                  TextSpan(text: report.siteConstraints!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (report.proposedItems != null && report.proposedItems!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 16, color: Color(0xFF0D9488)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(text: 'Đề xuất: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                                  TextSpan(text: report.proposedItems!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF134E4A))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (report.notes != null && report.notes!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.stickyNote, size: 16, color: Color(0xFF475569)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(text: 'Ghi chú: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  TextSpan(text: report.notes!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // 3. Quotation Items Cards
            if (effectiveQuotationItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFF2563EB), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BÁO GIÁ HẠNG MỤC THIẾT BỊ / DỊCH VỤ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.2),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${effectiveQuotationItems.length} mục',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...effectiveQuotationItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ),
                                Text(
                                  '${Formatters.formatCurrency(item.unitPrice)}/${item.unit}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              'SL: ${item.quantity} ${item.unit}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(item.totalAmount),
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.coins, color: Color(0xFFB45309), size: 18),
                        SizedBox(width: 8),
                        Text('Tổng giá trị báo giá:', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Text(
                      Formatters.formatCurrency(totalQuotationAmount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF9A3412)),
                    ),
                  ],
                ),
              ),
            ],

            // 4. Photos Showcase
            if (report.evidencePhotoUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(LucideIcons.image, color: AppColors.warmTextMuted, size: 16),
                  SizedBox(width: 6),
                  Text('Hình ảnh hiện trường / Sơ đồ khảo sát', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.evidencePhotoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final photoPath = report.evidencePhotoUrls[i];
                    final isLocal = photoPath.startsWith('/') || photoPath.contains('\\') || photoPath.startsWith('file:');
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: isLocal
                            ? Image.file(
                                File(photoPath),
                                height: 150,
                                width: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const SizedBox(width: 220),
                              )
                            : Image.network(
                                photoPath,
                                height: 150,
                                width: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const SizedBox(width: 220),
                              ),
                      ),
                    );
                  },
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
              children: [
                Icon(
                  isCompleted ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  color: isCompleted ? const Color(0xFF16A34A) : Colors.red.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'BÁO CÁO KHẢO SÁT HỆ THỐNG' : 'KẾ HOẠCH ĐÃ HỦY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF16A34A) : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Kế hoạch khảo sát đã hoàn thành. Không có dữ liệu báo cáo khảo sát ghi nhận.'
                  : 'Kế hoạch đã bị hủy.',
              style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
            ),
          ],
        ),
      );
    }



    return Container(
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isAlreadySubmitted) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'ĐÃ NỘP BÁO CÁO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ] else if (_isDraftSaved) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'ĐÃ LƯU BẢN NHÁP',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldLabel),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Dimension Inputs
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
            const SizedBox(height: 20),

            // ------------------ SECTION: TẠO BÁO GIÁ ĐÍNH KÈM (MOBILE NATIVE) ------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF0DFBD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.fileSpreadsheet, color: AppColors.goldPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Form Báo Giá Đính Kèm Khảo Sát',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_quotationItems.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_quotationItems.length} mục',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chọn thiết bị từ kho để thêm vào báo giá khảo sát:',
                    style: TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                  ),
                  const SizedBox(height: 12),

                  // Mobile Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(LucideIcons.boxes, size: 16),
                      label: const Text('Thêm từ kho', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        EquipmentPickerSheet.show(
                          context,
                          selectedItems: _quotationItems,
                          onAddPreset: (CatalogItemPreset preset) {
                            _addPresetItem(preset);
                          },
                          onAddCustomItem: (QuotationItemInput customItem) {
                            setState(() {
                              _quotationItems.add(customItem);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Chi tiết các hạng mục thiết bị/dịch vụ đã chọn:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                  ),
                  const SizedBox(height: 8),

                  // Selected Items List
                  if (_quotationItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8DFC8)),
                      ),
                      child: const Column(
                        children: [
                          Icon(LucideIcons.shoppingBag, color: AppColors.warmTextMuted, size: 28),
                          SizedBox(height: 6),
                          Text('Chưa chọn hạng mục báo giá nào', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                          Text('Bấm chọn thiết bị phía trên để thêm vào báo giá', style: TextStyle(fontSize: 11.5, color: AppColors.warmTextMuted)),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: List.generate(_quotationItems.length, (index) {
                        final item = _quotationItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEAD8B7)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F2EA),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(item.category, style: const TextStyle(fontSize: 10.5, color: AppColors.goldLabel, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                                    onPressed: () => setState(() => _quotationItems.removeAt(index)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Đơn giá', style: TextStyle(fontSize: 11, color: AppColors.warmTextMuted)),
                                      Text(Formatters.formatCurrency(item.unitPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                                    ],
                                  ),
                                  // Quantity Counter Stepper
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F2EA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFEAD8B7)),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (item.quantity > 1) {
                                              setState(() => item.quantity -= 1);
                                            } else {
                                              setState(() => _quotationItems.removeAt(index));
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(10),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(LucideIcons.minus, size: 14, color: AppColors.warmTextDark),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            '${item.quantity} ${item.unit}',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setState(() => item.quantity += 1),
                                          borderRadius: BorderRadius.circular(10),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(LucideIcons.plus, size: 14, color: AppColors.warmTextDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFF0E8DC)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Thành tiền:', style: TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted)),
                                  Text(
                                    Formatters.formatCurrency(item.totalAmount),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                  const SizedBox(height: 12),
                  // Financial Summary Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEAD8B7)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:', style: TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted)),
                            Text(Formatters.formatCurrency(_subtotalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                          ],
                        ),
                        if (_totalDiscountAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Giảm giá:', style: TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted)),
                              Text('- ${Formatters.formatCurrency(_totalDiscountAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            ],
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Thực tế (Tổng cộng):', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                            Text(
                              Formatters.formatCurrency(_totalQuotationAmount),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Photo Upload Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ảnh chụp mặt bằng khảo sát *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                ),
                if (_photoFiles.isNotEmpty)
                  Text(
                    'Đã chọn ${_photoFiles.length} ảnh',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_photoFiles.isEmpty && !_isAlreadySubmitted) ...[
              InkWell(
                onTap: _showImagePickerOptions,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0DFBD)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF7F2EA),
                        ),
                        child: const Icon(LucideIcons.camera, color: AppColors.goldPrimary, size: 22),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chụp ảnh hoặc chọn nhiều ảnh từ thư viện',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hỗ trợ tải lên cùng lúc nhiều ảnh bằng chứng mặt bằng',
                        style: TextStyle(fontSize: 11.5, color: AppColors.warmTextMuted),
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
                      return GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9EE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0DFBD)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.plus, color: AppColors.goldPrimary, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Thêm ảnh',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
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
                            borderRadius: BorderRadius.circular(16),
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
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
            const SizedBox(height: 16),

            if (_isAlreadySubmitted)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAD8B7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Đã nộp báo cáo khảo sát', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _isSubmitting ? null : _handleSaveDraft,
                        child: const Text('Lưu bản nháp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.goldPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldPrimary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Gửi báo cáo', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                      ),
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
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
          ),
        ],
      ),
    );
  }
}
