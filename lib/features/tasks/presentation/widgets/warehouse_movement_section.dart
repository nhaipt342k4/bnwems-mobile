import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  final Map<String, int> _selectedQuantities = {};
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _selectedQuantities[item.itemId] = item.quantity;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final movementItems = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => {'itemId': e.key, 'quantity': e.value})
        .toList();

    if (movementItems.isEmpty) {
      setState(() => _error = 'Vui lòng chọn ít nhất 1 thiết bị xuất/nhập kho.');
      return;
    }

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
          Row(
            children: [
              Icon(LucideIcons.package, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Ghi nhận Xuất / Nhập kho hiện trường',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.items.map((item) {
            final qty = _selectedQuantities[item.itemId] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
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
                        Text('Yêu cầu: ${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.minusCircle, size: 20, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: qty > 0 ? () => setState(() => _selectedQuantities[item.itemId] = qty - 1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$qty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _selectedQuantities[item.itemId] = qty + 1),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Ghi chú xuất kho',
            hintText: 'Lưu ý vận chuyển...',
            controller: _notesController,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
          ],
          const SizedBox(height: 16),
          AppButton(
            text: 'Xác nhận xuất kho',
            isFullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
