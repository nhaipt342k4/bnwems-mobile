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

  /// Ảnh minh chứng kiểm đếm thu hồi (đặc biệt cho thiết bị hỏng/mất).
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
  final CollectedEquipmentReport? existingSupplierReport;
  final List<WorkTaskItem> items;

  /// Thiết bị thuê NCC (theo giao dịch) — để lập báo cáo thu hồi nhóm Nhà cung cấp (reportType SUPPLIER).
  final List<SupplierTransaction> supplierTransactions;

  /// Bước 1: gửi báo cáo thu hồi
  final Future<void> Function(CollectedEquipmentReportSubmitInput input) onSubmit;

  /// Bước 2: xác nhận hoàn kho (null = không có bước này)
  final Future<void> Function()? onConfirmWarehouse;

  /// Trạng thái hoàn kho đã xác nhận (persistent)
  final bool isWarehouseConfirmed;

  /// Callback khi giá trị bồi thường thay đổi
  final void Function(double suggestedCompensation)? onCompensationChanged;

  const CollectedEquipmentReportSection({
    super.key,
    this.existingInternalReport,
    this.existingSupplierReport,
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

  // Nhóm NCC: đếm theo stItemId của từng dòng giao dịch NCC
  final Map<String, int> _supGoodQty = {};
  final Map<String, int> _supDamagedQty = {};
  final Map<String, int> _supLostQty = {};
  String? _submittingSupplierTxId;

  // Ảnh minh chứng kiểm đếm (hỏng/mất) cho báo cáo Kho công ty.
  final ImagePicker _picker = ImagePicker();
  final List<File> _photoFiles = [];

  bool _isSubmitting = false;
  bool _isConfirmingWarehouse = false;
  String? _error;

  // Bước hiện tại: 0 = chưa gửi, 1 = đã gửi báo cáo (chờ hoàn kho), 2 = đã hoàn kho
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
    for (final tx in widget.supplierTransactions) {
      for (final it in tx.items) {
        _supGoodQty[it.stItemId] = it.quantity;
        _supDamagedQty[it.stItemId] = 0;
        _supLostQty[it.stItemId] = 0;
      }
    }
  }

  Future<void> _handleSubmitSupplierReport(SupplierTransaction tx) async {
    final reportItems = tx.items.map((it) {
      return {
        'itemId': it.itemId,
        'goodQuantity': _supGoodQty[it.stItemId] ?? 0,
        'damagedQuantity': _supDamagedQty[it.stItemId] ?? 0,
        'lostQuantity': _supLostQty[it.stItemId] ?? 0,
      };
    }).toList();

    setState(() {
      _submittingSupplierTxId = tx.transactionId;
      _error = null;
    });
    try {
      await widget.onSubmit(
        CollectedEquipmentReportSubmitInput(
          reportType: 'SUPPLIER',
          transactionId: tx.transactionId,
          items: reportItems,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submittingSupplierTxId = null);
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.primary),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotos(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotos(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.camera, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('Ảnh minh chứng (khuyến nghị chụp thiết bị hỏng/mất)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < _photoFiles.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_photoFiles[i], width: 76, height: 76, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photoFiles.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
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
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(LucideIcons.plus, color: AppColors.textMuted),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: step == 2
            ? Colors.green.shade50
            : step == 1
                ? Colors.orange.shade50
                : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step == 2
              ? Colors.green.shade300
              : step == 1
                  ? Colors.orange.shade300
                  : AppColors.borderLight,
          width: step >= 1 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──── Header ────
          Row(
            children: [
              Icon(
                step == 2 ? LucideIcons.checkCircle2 : LucideIcons.packageCheck,
                size: 18,
                color: step == 2 ? Colors.green.shade700 : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Báo cáo kiểm đếm thu hồi thiết bị',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Badge trạng thái
              if (step == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(20),
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
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 12),

          // ──── Bước 2: Đã hoàn kho hoàn toàn ────
          if (step == 2) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.warehouse, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Báo cáo thu hồi đã gửi và thiết bị đã được xác nhận hoàn kho thành công.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800),
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

          // ──── Bước 1: Đã gửi báo cáo, chờ xác nhận hoàn kho ────
          else if (step == 1) ...[
            // Banner bước hiện tại
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Báo cáo đã gửi nhưng thiết bị CHƯA được nhập lại kho. Nhấn "Xác nhận hoàn kho" để hoàn tất — trạng thái sẽ đồng bộ về web.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.existingInternalReport != null)
              _buildSubmittedReportView(widget.existingInternalReport!),
            const SizedBox(height: 12),
            if (widget.onConfirmWarehouse != null)
              AppButton(
                text: 'Xác nhận hoàn kho',
                isFullWidth: true,
                isLoading: _isConfirmingWarehouse,
                onPressed: _handleConfirmWarehouse,
              ),
          ]

          // ──── Bước 0: Chưa gửi báo cáo ────
          else ...[
            const Text('Thiết bị Kho công ty:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.items
                .where((i) => i.source == null || i.source == 'INTERNAL')
                .map((item) => _buildItemRow(item)),
            const SizedBox(height: 12),

            // Banner đề xuất bồi thường
            if (compensation > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đề xuất bồi thường hư hỏng/mất',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatCurrency(compensation),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                          Text(
                            '(Đã tự động điền vào ô Bồi thường ở mục Quyết toán)',
                            style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            _buildPhotoPicker(),

            AppButton(
              text: 'Gửi báo cáo thu hồi Kho công ty',
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _handleSubmitReport,
            ),
          ],

          // ──── Nhóm Nhà cung cấp (thu hồi đồ thuê NCC) ────
          ..._buildSupplierSection(),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSupplierSection() {
    final txsWithItems = widget.supplierTransactions.where((t) => t.items.isNotEmpty).toList();
    if (txsWithItems.isEmpty) return const [];
    final submitted = widget.existingSupplierReport != null;
    return [
      const SizedBox(height: 16),
      const Divider(height: 1),
      const SizedBox(height: 12),
      Row(
        children: [
          const Icon(LucideIcons.truck, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('Thiết bị thuê Nhà cung cấp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          if (submitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(20)),
              child: const Text('Đã gửi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
        ],
      ),
      const SizedBox(height: 10),
      if (submitted)
        _buildSubmittedReportView(widget.existingSupplierReport!)
      else
        ...txsWithItems.map(_buildSupplierTxCard),
    ];
  }

  Widget _buildSupplierTxCard(SupplierTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${tx.supplierName} · ${tx.transactionCode}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ...tx.items.map((it) {
            final good = _supGoodQty[it.stItemId] ?? it.quantity;
            final damaged = _supDamagedQty[it.stItemId] ?? 0;
            final lost = _supLostQty[it.stItemId] ?? 0;
            final hasIssue = damaged > 0 || lost > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasIssue ? Colors.orange.shade50 : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: hasIssue ? Border.all(color: Colors.orange.shade200) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${it.itemName} (${it.quantity})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQtyPicker('Tốt', good, AppColors.completedText,
                          onDec: good > 0 ? () => setState(() => _adjust(_supGoodQty, _supDamagedQty, _supLostQty, it.stItemId, 'good', -1)) : null,
                          onInc: (damaged > 0 || lost > 0) ? () => setState(() => _adjust(_supGoodQty, _supDamagedQty, _supLostQty, it.stItemId, 'good', 1)) : null),
                      _buildQtyPicker('Hỏng', damaged, AppColors.inProgressText,
                          onDec: damaged > 0 ? () => setState(() => _adjust(_supGoodQty, _supDamagedQty, _supLostQty, it.stItemId, 'damaged', -1)) : null,
                          onInc: good > 0 ? () => setState(() => _adjust(_supGoodQty, _supDamagedQty, _supLostQty, it.stItemId, 'damaged', 1)) : null),
                      _buildQtyPicker('Mất', lost, AppColors.cancelledText,
                          onDec: lost > 0 ? () => setState(() => _adjust(_supGoodQty, _supDamagedQty, _supLostQty, it.stItemId, 'lost', -1)) : null,
                          onInc: good > 0 ? () => setState(() => _adjust(_supGoodQty, _supDamagedQty, _supLostQty, it.stItemId, 'lost', 1)) : null),
                    ],
                  ),
                  if (hasIssue && it.unitCost > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Đền NCC: ${damaged + lost} × ${Formatters.formatCurrency(it.unitCost)} = ${Formatters.formatCurrency((damaged + lost) * it.unitCost)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          AppButton(
            text: 'Gửi báo cáo thu hồi NCC',
            isFullWidth: true,
            isLoading: _submittingSupplierTxId == tx.transactionId,
            onPressed: () => _handleSubmitSupplierReport(tx),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(WorkTaskItem item) {
    final id = item.itemId;
    final good = _goodQty[id] ?? item.quantity;
    final damaged = _damagedQty[id] ?? 0;
    final lost = _lostQty[id] ?? 0;
    final hasIssue = damaged > 0 || lost > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasIssue ? Colors.orange.shade50 : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: hasIssue ? Border.all(color: Colors.orange.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.name} (${item.quantity} ${item.unit})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              if (item.rentalPrice > 0)
                Text(
                  Formatters.formatCurrency(item.rentalPrice),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQtyPicker('Tốt', good, AppColors.completedText,
                  onDec: good > 0 ? () => _updateQtyAndNotify(() => _adjust(_goodQty, _damagedQty, _lostQty, id, 'good', -1)) : null,
                  onInc: (damaged > 0 || lost > 0) ? () => _updateQtyAndNotify(() => _adjust(_goodQty, _damagedQty, _lostQty, id, 'good', 1)) : null),
              _buildQtyPicker('Hỏng', damaged, AppColors.inProgressText,
                  onDec: damaged > 0 ? () => _updateQtyAndNotify(() => _adjust(_goodQty, _damagedQty, _lostQty, id, 'damaged', -1)) : null,
                  onInc: good > 0 ? () => _updateQtyAndNotify(() => _adjust(_goodQty, _damagedQty, _lostQty, id, 'damaged', 1)) : null),
              _buildQtyPicker('Mất', lost, AppColors.cancelledText,
                  onDec: lost > 0 ? () => _updateQtyAndNotify(() => _adjust(_goodQty, _damagedQty, _lostQty, id, 'lost', -1)) : null,
                  onInc: good > 0 ? () => _updateQtyAndNotify(() => _adjust(_goodQty, _damagedQty, _lostQty, id, 'lost', 1)) : null),
            ],
          ),
          if (hasIssue && item.rentalPrice > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Bồi thường: ${damaged + lost} × ${Formatters.formatCurrency(item.rentalPrice)} = ${Formatters.formatCurrency((damaged + lost) * item.rentalPrice)}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
            ),
          ],
        ],
      ),
    );
  }

  // Điều chỉnh 1 đơn vị và LUÔN giữ tổng: tốt + hỏng + mất = số lượng thu hồi.
  // Tăng hỏng/mất tự trừ vào "Tốt"; giảm hỏng/mất tự cộng lại "Tốt". Trả về false nếu không hợp lệ (bị chặn).
  bool _adjust(Map<String, int> g, Map<String, int> d, Map<String, int> l, String id, String kind, int dir) {
    int good = g[id] ?? 0;
    int dmg = d[id] ?? 0;
    int lost = l[id] ?? 0;
    switch (kind) {
      case 'good':
        if (dir > 0) {
          // Tăng tốt = kéo 1 từ hỏng (ưu tiên) rồi tới mất.
          if (dmg > 0) {
            dmg--;
            good++;
          } else if (lost > 0) {
            lost--;
            good++;
          } else {
            return false;
          }
        } else {
          // Giảm tốt = đánh dấu 1 thành hỏng.
          if (good > 0) {
            good--;
            dmg++;
          } else {
            return false;
          }
        }
        break;
      case 'damaged':
        if (dir > 0) {
          if (good > 0) {
            good--;
            dmg++;
          } else {
            return false;
          }
        } else {
          if (dmg > 0) {
            dmg--;
            good++;
          } else {
            return false;
          }
        }
        break;
      default: // lost
        if (dir > 0) {
          if (good > 0) {
            good--;
            lost++;
          } else {
            return false;
          }
        } else {
          if (lost > 0) {
            lost--;
            good++;
          } else {
            return false;
          }
        }
    }
    g[id] = good;
    d[id] = dmg;
    l[id] = lost;
    return true;
  }

  Widget _buildQtyPicker(String label, int value, Color color, {VoidCallback? onDec, VoidCallback? onInc}) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        InkWell(
          onTap: onDec,
          child: Icon(LucideIcons.minusCircle, size: 16, color: onDec == null ? AppColors.textMuted.withValues(alpha: 0.3) : AppColors.textMuted),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$value', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        InkWell(
          onTap: onInc,
          child: Icon(LucideIcons.plusCircle, size: 16, color: onInc == null ? color.withValues(alpha: 0.3) : color),
        ),
      ],
    );
  }

  Widget _buildSubmittedReportView(CollectedEquipmentReport report) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.completedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.completedText.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppColors.completedText, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'ĐÃ GỬI BÁO CÁO KIỂM ĐẾM THU HỒI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.completedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...report.items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${i.name}: Tốt: ${i.goodQuantity} | Hỏng: ${i.damagedQuantity} | Mất: ${i.lostQuantity}',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
