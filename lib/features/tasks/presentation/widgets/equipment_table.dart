import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/work_task_models.dart';

class EquipmentTable extends StatelessWidget {
  final List<WorkTaskItem> items;

  const EquipmentTable({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final internalItems = items.where((i) => i.source == null || i.source == 'INTERNAL').toList();
    final supplierItems = items.where((i) => i.source == 'SUPPLIER').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table 1: Kho doanh nghiệp
        _buildTableSection(
          title: 'Kho doanh nghiệp (theo pick-list)',
          items: internalItems,
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 16),

        // Table 2: Nhà cung cấp (nếu có)
        if (supplierItems.isNotEmpty)
          _buildTableSection(
            title: 'Nhà cung cấp (theo đơn thuê)',
            items: supplierItems,
            accentColor: AppColors.leaderPurple,
          ),
      ],
    );
  }

  Widget _buildTableSection({
    required String title,
    required List<WorkTaskItem> items,
    required Color accentColor,
  }) {
    return Container(
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
              Container(width: 4, height: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
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
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      DataCell(Text(item.unit, style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataCell(
                        Text(
                          item.quantityAvailable != null ? '${item.quantityAvailable}' : '--',
                          style: TextStyle(
                            fontSize: 12,
                            color: (item.quantityAvailable ?? 0) < item.quantity ? AppColors.cancelledText : AppColors.completedText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
