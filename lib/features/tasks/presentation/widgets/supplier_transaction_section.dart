import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/work_task_models.dart';

class SupplierTransactionSection extends StatelessWidget {
  final List<SupplierTransaction> transactions;
  final Future<void> Function(String transactionId, String stItemId, int receivedQuantity) onReceiveItem;
  // Chỉ xem (manager review): ẩn nút bút chì cập nhật SL nhận.
  final bool readOnly;

  const SupplierTransactionSection({
    super.key,
    required this.transactions,
    required this.onReceiveItem,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.truck, size: 18, color: AppColors.leaderPurple),
            SizedBox(width: 8),
            Text(
              'Nhận thiết bị từ Nhà cung cấp (Đơn thuê)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...transactions.map(
          (tx) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tx.supplierName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(tx.transactionCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  ],
                ),
                Text(tx.serviceTitle, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                Text('Chi phí dự kiến: ${Formatters.formatCurrency(tx.estimatedCost)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 10),

                const Text('Danh sách hạng mục thuê:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...tx.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.itemName} (${item.quantity} cái)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Đã nhận: ${item.receivedQuantity}/${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.receivedQuantity >= item.quantity ? AppColors.completedText : AppColors.inProgressText,
                              ),
                            ),
                            if (!readOnly) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(LucideIcons.edit2, size: 16, color: AppColors.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showUpdateDialog(context, tx.transactionId, item),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showUpdateDialog(BuildContext context, String transactionId, SupplierTransactionItem item) {
    final controller = TextEditingController(text: item.receivedQuantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật SL đã nhận: ${item.itemName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số lượng thực nhận'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text) ?? 0;
              Navigator.of(context).pop();
              await onReceiveItem(transactionId, item.stItemId, qty);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
