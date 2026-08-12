import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/work_task_models.dart';

class EquipmentTable extends StatefulWidget {
  final List<WorkTaskItem> items;
  final bool isWarehouseConfirmed;
  final Future<void> Function(String notes)? onConfirmWarehouseMovement;

  const EquipmentTable({
    super.key,
    required this.items,
    this.isWarehouseConfirmed = false,
    this.onConfirmWarehouseMovement,
  });

  @override
  State<EquipmentTable> createState() => _EquipmentTableState();
}

class _EquipmentTableState extends State<EquipmentTable> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isConfirmed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isConfirmed = widget.isWarehouseConfirmed;
  }

  @override
  void didUpdateWidget(covariant EquipmentTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWarehouseConfirmed != oldWidget.isWarehouseConfirmed) {
      setState(() {
        _isConfirmed = widget.isWarehouseConfirmed;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (widget.onConfirmWarehouseMovement == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onConfirmWarehouseMovement!(_notesController.text.trim());
      setState(() {
        _isConfirmed = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final internalItems = widget.items.where((i) => i.source == null || i.source == 'INTERNAL').toList();
    final supplierItems = widget.items.where((i) => i.source == 'SUPPLIER').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table 1: Kho doanh nghiệp
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(width: 4, height: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Kho doanh nghiệp (theo pick-list)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isConfirmed) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'ĐÃ XÁC NHẬN XUẤT KHO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (internalItems.isEmpty)
                const Text('Không có thiết bị trong nhóm này.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 36,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    headingRowColor: WidgetStateProperty.all(AppColors.background),
                    columns: const [
                      DataColumn(label: Text('Mặt hàng / Thiết bị', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ĐVT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('SL yêu cầu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('SL khả dụng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                    rows: internalItems.map((item) {
                      final avail = item.quantityAvailable ?? item.quantity;
                      // So đủ/thiếu theo phần KHO NỘI BỘ ròng (đã trừ phần thuê NCC), không theo tổng đặt.
                      final isSufficient = avail >= item.internalNeed;
                      return DataRow(
                        cells: [
                          DataCell(Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          DataCell(Text(item.unit, style: const TextStyle(fontSize: 12))),
                          DataCell(
                            item.quantityRented > 0
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('kho ${item.internalNeed} · thuê ${item.quantityRented}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    ],
                                  )
                                : Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          DataCell(
                            Text(
                              '$avail',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSufficient ? AppColors.completedText : AppColors.cancelledText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              if (widget.onConfirmWarehouseMovement != null) ...[
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Ghi chú trước khi xuất kho (nếu có)',
                  hintText: 'Nhập ghi chú xuất kho...',
                  controller: _notesController,
                  readOnly: _isConfirmed,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
                ],
                const SizedBox(height: 12),
                AppButton(
                  text: _isConfirmed ? 'Đã xác nhận xuất kho' : 'Xác nhận xuất kho',
                  isFullWidth: true,
                  isLoading: _isSubmitting,
                  onPressed: _isConfirmed ? null : _handleConfirm,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Table 2: Nhà cung cấp (nếu có)
        if (supplierItems.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 16, color: AppColors.leaderPurple),
                    const SizedBox(width: 8),
                    const Text(
                      'Nhà cung cấp (theo đơn thuê)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 36,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    headingRowColor: WidgetStateProperty.all(AppColors.background),
                    columns: const [
                      DataColumn(label: Text('Mặt hàng / Thiết bị', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ĐVT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('SL yêu cầu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                    rows: supplierItems.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          DataCell(Text(item.unit, style: const TextStyle(fontSize: 12))),
                          DataCell(Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
