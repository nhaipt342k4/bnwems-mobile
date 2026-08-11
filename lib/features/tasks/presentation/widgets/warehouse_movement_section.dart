import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/work_task_models.dart';

class WarehouseMovementSubmitInput {
  final List<Map<String, dynamic>> items;
  final String? notes;

  WarehouseMovementSubmitInput({
    required this.items,
    this.notes,
  });
}

class WarehouseMovementSection extends StatefulWidget {
  final List<WorkTaskItem> items;
  final Future<void> Function(WarehouseMovementSubmitInput input) onSubmit;

  const WarehouseMovementSection({
    super.key,
    required this.items,
    required this.onSubmit,
  });

  @override
  State<WarehouseMovementSection> createState() => _WarehouseMovementSectionState();
}

class _WarehouseMovementSectionState extends State<WarehouseMovementSection> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isConfirmed = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final movementItems = widget.items
        .map((e) => {'itemId': e.itemId, 'quantity': e.quantity})
        .toList();

    if (movementItems.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        WarehouseMovementSubmitInput(
          items: movementItems,
          notes: _notesController.text.trim(),
        ),
      );
      setState(() {
        _isConfirmed = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          Row(
            children: [
              const Icon(LucideIcons.package, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Xác nhận Xuất kho thiết bị hiện trường',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              if (_isConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ),
          const SizedBox(height: 12),
          ...widget.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Số lượng yêu cầu xuất kho: ${item.quantity} ${item.unit}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity} ${item.unit}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Ghi chú xuất kho (nếu có)',
            hintText: 'Nhập ghi chú cho thủ kho...',
            controller: _notesController,
            readOnly: _isConfirmed,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
          ],
          const SizedBox(height: 16),
          AppButton(
            text: _isConfirmed ? 'Đã xác nhận xuất kho' : 'Xác nhận xuất kho',
            isFullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _isConfirmed ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}
