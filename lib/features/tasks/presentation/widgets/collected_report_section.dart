import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/work_task_models.dart';

class CollectedEquipmentReportSubmitInput {
  final String reportType; // 'INTERNAL' | 'SUPPLIER'
  final String? transactionId;
  final String? notes;
  final List<Map<String, dynamic>> items;
  final List<File> photoFiles;

  CollectedEquipmentReportSubmitInput({
    required this.reportType,
    this.transactionId,
    this.notes,
    required this.items,
    this.photoFiles = const [],
  });
}

class CollectedEquipmentReportSection extends StatefulWidget {
  final CollectedEquipmentReport? existingInternalReport;
  final List<CollectedEquipmentReport> existingSupplierReports;
  final List<WorkTaskItem> items;
  final List<SupplierTransaction> supplierTransactions;
  final Future<void> Function(CollectedEquipmentReportSubmitInput input) onSubmit;
  final Future<void> Function()? onConfirmWarehouse;
  final bool isWarehouseConfirmed;
  final void Function(double suggestedCompensation)? onCompensationChanged;

  const CollectedEquipmentReportSection({
    super.key,
    this.existingInternalReport,
    this.existingSupplierReports = const [],
    required this.items,
    this.supplierTransactions = const [],
    required this.onSubmit,
    this.onConfirmWarehouse,
    this.isWarehouseConfirmed = false,
    this.onCompensationChanged,
  });

  @override
  State<CollectedEquipmentReportSection> createState() => _CollectedEquipmentReportSectionState();
}

class _CollectedEquipmentReportSectionState extends State<CollectedEquipmentReportSection> {
  final Map<String, int> _goodQty = {};
  final Map<String, int> _damagedQty = {};
  final Map<String, int> _lostQty = {};

  final ImagePicker _picker = ImagePicker();
  final List<File> _photoFiles = [];

  bool _isSubmitting = false;
  bool _isConfirmingWarehouse = false;
  String? _error;

  int get _step {
    if (widget.isWarehouseConfirmed) return 2;
    if (widget.existingInternalReport != null) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _goodQty[item.itemId] = item.quantity;
      _damagedQty[item.itemId] = 0;
      _lostQty[item.itemId] = 0;
    }
  }

  double get _totalCompensation {
    double total = 0;
    for (final item in widget.items) {
      final damaged = _damagedQty[item.itemId] ?? 0;
      final lost = _lostQty[item.itemId] ?? 0;
      total += (damaged + lost) * item.rentalPrice;
    }
    return total;
  }

  void _updateQtyAndNotify(VoidCallback update) {
    setState(update);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCompensationChanged?.call(_totalCompensation);
    });
  }

  Future<void> _handleSubmitReport() async {
    final reportItems = widget.items.map((item) {
      final id = item.itemId;
      return {
        'itemId': id,
        'goodQuantity': _goodQty[id] ?? 0,
        'damagedQuantity': _damagedQty[id] ?? 0,
        'lostQuantity': _lostQty[id] ?? 0,
      };
    }).toList();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        CollectedEquipmentReportSubmitInput(
          reportType: 'INTERNAL',
          items: reportItems,
          photoFiles: List.from(_photoFiles),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickPhotos(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (img != null) setState(() => _photoFiles.add(File(img.path)));
      } else {
        final imgs = await _picker.pickMultiImage(imageQuality: 85);
        if (imgs.isNotEmpty) setState(() => _photoFiles.addAll(imgs.map((x) => File(x.path))));
      }
    } catch (_) {}
  }

  void _showPhotoPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.goldPrimary),
                title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhotos(ImageSource.camera);
                },
              ),
              const Divider(height: 1, color: Color(0xFFF0E8DC)),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.goldPrimary),
                title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhotos(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.camera, size: 15, color: AppColors.goldPrimary),
            SizedBox(width: 6),
            Expanded(
              child: Text('Ảnh minh chứng (khuyến nghị chụp thiết bị hỏng/mất)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < _photoFiles.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_photoFiles[i], width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _photoFiles.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _showPhotoPicker,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0DFBD)),
                  ),
                  child: const Icon(LucideIcons.plus, color: AppColors.goldPrimary, size: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _handleConfirmWarehouse() async {
    setState(() {
      _isConfirmingWarehouse = true;
      _error = null;
    });
    try {
      await widget.onConfirmWarehouse?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isConfirmingWarehouse = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isConfirmingWarehouse = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final compensation = _totalCompensation;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: step == 2
            ? const Color(0xFFF0FDF4)
            : step == 1
                ? const Color(0xFFFFF9EE)
                : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: step == 2
              ? const Color(0xFF86EFAC)
              : step == 1
                  ? const Color(0xFFF0DFBD)
                  : const Color(0xFFF0E8DC),
          width: step >= 1 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                step == 2 ? LucideIcons.checkCircle2 : LucideIcons.packageCheck,
                size: 18,
                color: step == 2 ? const Color(0xFF16A34A) : AppColors.goldPrimary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Báo cáo kiểm đếm thu hồi thiết bị',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmTextDark,
                  ),
                ),
              ),
              if (step == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertTriangle, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Chờ hoàn kho', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              if (step == 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.checkCircle2, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Đã hoàn kho', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (step == 2) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.warehouse, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Báo cáo thu hồi đã gửi và thiết bị đã được xác nhận hoàn kho thành công.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.existingInternalReport != null) ...[
              const SizedBox(height: 10),
              _buildSubmittedReportView(widget.existingInternalReport!),
            ],
          ]
          else if (step == 1) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0DFBD)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: AppColors.goldLabel, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Báo cáo đã gửi nhưng thiết bị CHƯA được nhập lại kho. Nhấn "Xác nhận hoàn kho" để hoàn tất.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldLabel),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.existingInternalReport != null)
              _buildSubmittedReportView(widget.existingInternalReport!),
            const SizedBox(height: 14),
            if (widget.onConfirmWarehouse != null)
              AppButton(
                text: 'Xác nhận hoàn kho',
                isFullWidth: true,
                isLoading: _isConfirmingWarehouse,
                onPressed: _handleConfirmWarehouse,
              ),
          ]
          else ...[
            const Text('Thiết bị Kho công ty:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
            const SizedBox(height: 8),
            ...widget.items
                .where((i) => i.source == null || i.source == 'INTERNAL')
                .map((item) => _buildItemRow(item)),
            const SizedBox(height: 12),

            if (compensation > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0DFBD)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: AppColors.goldLabel, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đề xuất bồi thường hư hỏng/mất',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldLabel),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatCurrency(compensation),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            _buildPhotoPicker(),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 12),
            ],

            AppButton(
              text: 'Gửi báo cáo thu hồi Kho công ty',
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _handleSubmitReport,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(WorkTaskItem item) {
    final good = _goodQty[item.itemId] ?? item.quantity;
    final damaged = _damagedQty[item.itemId] ?? 0;
    final lost = _lostQty[item.itemId] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.name} (${item.quantity} ${item.unit})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
          const SizedBox(height: 4),
          Row(
            children: [
              _counter('Tốt', good, (val) {
                _updateQtyAndNotify(() {
                  _goodQty[item.itemId] = val;
                });
              }),
              const SizedBox(width: 8),
              _counter('Hỏng', damaged, (val) {
                _updateQtyAndNotify(() {
                  _damagedQty[item.itemId] = val;
                });
              }),
              const SizedBox(width: 8),
              _counter('Mất', lost, (val) {
                _updateQtyAndNotify(() {
                  _lostQty[item.itemId] = val;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counter(String label, int value, ValueChanged<int> onChanged) {
    Color bg = const Color(0xFFF8FAFC);
    Color border = const Color(0xFFE2E8F0);
    Color textCol = const Color(0xFF334155);
    Color iconCol = const Color(0xFF2563EB);

    if (label == 'Tốt') {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      textCol = const Color(0xFF15803D);
      iconCol = const Color(0xFF16A34A);
    } else if (label == 'Hỏng') {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      textCol = const Color(0xFFB45309);
      iconCol = const Color(0xFFD97706);
    } else if (label == 'Mất') {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECDD3);
      textCol = const Color(0xFFBE123C);
      iconCol = const Color(0xFFE11D48);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: textCol)),
          const SizedBox(width: 8),
          InkWell(
            onTap: value > 0 ? () => onChanged(value - 1) : null,
            child: Icon(LucideIcons.minusCircle, size: 16, color: value > 0 ? iconCol : const Color(0xFFCBD5E1)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textCol)),
          ),
          InkWell(
            onTap: () => onChanged(value + 1),
            child: Icon(LucideIcons.plusCircle, size: 16, color: iconCol),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedReportView(CollectedEquipmentReport report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in report.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warmTextDark)),
                  Text(
                    'Tốt: ${item.goodQuantity} · Hỏng: ${item.damagedQuantity} · Mất: ${item.lostQuantity}',
                    style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
