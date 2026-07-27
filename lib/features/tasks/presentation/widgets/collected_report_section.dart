import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/work_task_models.dart';

class CollectedEquipmentReportSubmitInput {
  final String reportType; // 'INTERNAL' | 'SUPPLIER'
  final String? transactionId;
  final String? notes;
  final List<Map<String, dynamic>> items;

  CollectedEquipmentReportSubmitInput({
    required this.reportType,
    this.transactionId,
    this.notes,
    required this.items,
  });
}

class CollectedEquipmentReportSection extends StatefulWidget {
  final CollectedEquipmentReport? existingInternalReport;
  final CollectedEquipmentReport? existingSupplierReport;
  final List<WorkTaskItem> items;
  final Future<void> Function(CollectedEquipmentReportSubmitInput input) onSubmit;

  const CollectedEquipmentReportSection({
    super.key,
    this.existingInternalReport,
    this.existingSupplierReport,
    required this.items,
    required this.onSubmit,
  });

  @override
  State<CollectedEquipmentReportSection> createState() => _CollectedEquipmentReportSectionState();
}

class _CollectedEquipmentReportSectionState extends State<CollectedEquipmentReportSection> {
  final Map<String, int> _goodQty = {};
  final Map<String, int> _damagedQty = {};
  final Map<String, int> _lostQty = {};
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _goodQty[item.itemId] = item.quantity;
      _damagedQty[item.itemId] = 0;
      _lostQty[item.itemId] = 0;
    }
  }

  Future<void> _handleSubmit(String reportType) async {
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
          reportType: reportType,
          items: reportItems,
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
              Icon(LucideIcons.packageCheck, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Báo cáo kiểm đếm thu hồi thiết bị',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.existingInternalReport != null) ...[
            _buildSubmittedReportView('Kho doanh nghiệp (Công ty)', widget.existingInternalReport!),
          ] else ...[
            const Text('Thiết bị Kho công ty:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.items.where((i) => i.source == null || i.source == 'INTERNAL').map((item) => _buildItemRow(item)),
            const SizedBox(height: 12),
            AppButton(
              text: 'Gửi báo cáo thu hồi Kho công ty',
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: () => _handleSubmit('INTERNAL'),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(WorkTaskItem item) {
    final id = item.itemId;
    final good = _goodQty[id] ?? item.quantity;
    final damaged = _damagedQty[id] ?? 0;
    final lost = _lostQty[id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.name} (${item.quantity} ${item.unit})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQtyPicker('Tốt', good, (val) => setState(() => _goodQty[id] = val), AppColors.completedText),
              _buildQtyPicker('Hỏng', damaged, (val) => setState(() => _damagedQty[id] = val), AppColors.inProgressText),
              _buildQtyPicker('Mất', lost, (val) => setState(() => _lostQty[id] = val), AppColors.cancelledText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyPicker(String label, int value, ValueChanged<int> onChanged, Color color) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        InkWell(
          onTap: value > 0 ? () => onChanged(value - 1) : null,
          child: const Icon(LucideIcons.minusCircle, size: 16, color: AppColors.textMuted),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$value', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        InkWell(
          onTap: () => onChanged(value + 1),
          child: Icon(LucideIcons.plusCircle, size: 16, color: color),
        ),
      ],
    );
  }

  Widget _buildSubmittedReportView(String title, CollectedEquipmentReport report) {
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
              Text('ĐÃ GỬI BÁO CÁO THU HỒI ($title)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.completedText)),
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
