import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(width: 3.5, height: 16, color: AppColors.goldPrimary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Kho doanh nghiệp (theo pick-list)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmTextDark,
                              fontFamily: 'serif',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isConfirmed) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'ĐÃ XÁC NHẬN XUẤT KHO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              if (internalItems.isEmpty)
                const Text('Không có thiết bị trong nhóm này.', style: TextStyle(fontSize: 13, color: AppColors.warmTextMuted))
              else ...[
                // Clean Custom Table Header
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Text('Mặt hàng / Thiết bị', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('ĐVT', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('SL yêu cầu', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF0E8DC)),
                const SizedBox(height: 2),

                // Table Rows
                ...internalItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFFAF6F0), width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.unit,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (widget.onConfirmWarehouseMovement != null) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ghi chú trước khi xuất kho (nếu có)',
                  hintText: 'Nhập ghi chú xuất kho...',
                  controller: _notesController,
                  readOnly: _isConfirmed,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isConfirmed || _isSubmitting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      disabledBackgroundColor: const Color(0xFFEAD8B7),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isConfirmed ? 'Đã xác nhận xuất kho' : 'Xác nhận xuất kho',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                          ),
                  ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 3.5, height: 16, color: const Color(0xFF7E22CE)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Nhà cung cấp (theo đơn thuê)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmTextDark,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Text('Mặt hàng / Thiết bị', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('ĐVT', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('SL yêu cầu', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF0E8DC)),
                const SizedBox(height: 2),
                ...supplierItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFFAF6F0), width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(item.unit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${item.quantity}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
