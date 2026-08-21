import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/quotation_item_model.dart';

class EquipmentPickerSheet extends StatefulWidget {
  final List<QuotationItemInput> selectedItems;
  final Function(CatalogItemPreset preset) onAddPreset;
  final Function(QuotationItemInput customItem) onAddCustomItem;

  const EquipmentPickerSheet({
    super.key,
    required this.selectedItems,
    required this.onAddPreset,
    required this.onAddCustomItem,
  });

  static Future<void> show(
    BuildContext context, {
    required List<QuotationItemInput> selectedItems,
    required Function(CatalogItemPreset preset) onAddPreset,
    required Function(QuotationItemInput customItem) onAddCustomItem,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EquipmentPickerSheet(
        selectedItems: selectedItems,
        onAddPreset: onAddPreset,
        onAddCustomItem: onAddCustomItem,
      ),
    );
  }

  @override
  State<EquipmentPickerSheet> createState() => _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends State<EquipmentPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';

  final categories = [
    'Tất cả',
    'Máy quay & Flycam',
    'Loa',
    'Đèn Par LED',
    'Thảm sân khấu',
    'Bàn chữ nhật',
    'Cổng hoa',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getItemQuantity(String name) {
    final idx = widget.selectedItems.indexWhere((i) => i.name.toLowerCase() == name.toLowerCase());
    return idx >= 0 ? widget.selectedItems[idx].quantity : 0;
  }

  void _showCustomDialog() {
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

              final customItem = QuotationItemInput(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                category: categoryCtrl.text.trim().isEmpty ? 'Khác' : categoryCtrl.text.trim(),
                unit: unitCtrl.text.trim().isEmpty ? 'Cái' : unitCtrl.text.trim(),
                quantity: qty < 1 ? 1 : qty,
                unitPrice: price,
                discountPerItem: discount,
              );

              widget.onAddCustomItem(customItem);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Thêm vào báo giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final filteredList = defaultEquipmentCatalog.where((item) {
      final matchesCat = _selectedCategory == 'Tất cả' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: const Color(0xFFF0E8DC), borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF9EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.boxes, color: AppColors.goldPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kho Thiết Bị & Dịch Vụ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                    Text('Chọn thiết bị từ danh mục để tạo báo giá', style: TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                  ],
                ),
              ),
              InkWell(
                onTap: _showCustomDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    border: Border.all(color: AppColors.goldPrimary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.plus, size: 14, color: AppColors.goldPrimary),
                      SizedBox(width: 4),
                      Text('Tùy chỉnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFC8)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search, color: AppColors.warmTextMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm thiết bị theo tên...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(LucideIcons.x, color: AppColors.warmTextMuted, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (ctx, idx) {
                final cat = categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.warmTextDark,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.goldPrimary,
                  backgroundColor: const Color(0xFFFAF6EE),
                  side: BorderSide(color: isSelected ? AppColors.goldPrimary : const Color(0xFFE0D5C1)),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Equipment List
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy thiết bị phù hợp', style: TextStyle(color: AppColors.warmTextMuted, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, index) {
                      final item = filteredList[index];
                      final qty = _getItemQuantity(item.name);
                      final isSelected = qty > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF9EE) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.goldPrimary : const Color(0xFFF0E8DC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.15) : const Color(0xFFFAF6EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isSelected ? LucideIcons.check : LucideIcons.box,
                                color: isSelected ? AppColors.goldPrimary : AppColors.warmTextMuted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.category} · ${Formatters.formatCurrency(item.defaultPrice)} / ${item.unit}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                widget.onAddPreset(item);
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.goldPrimary : const Color(0xFFFAF6EE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? AppColors.goldPrimary : const Color(0xFFEAD8B7)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? LucideIcons.plus : LucideIcons.plus,
                                      size: 14,
                                      color: isSelected ? Colors.white : AppColors.goldPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSelected ? 'Thêm ($qty)' : 'Thêm',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppColors.goldPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

          // Bottom Done Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.selectedItems.isEmpty
                    ? 'Đóng'
                    : 'Xác nhận (${widget.selectedItems.length} hạng mục đã chọn)',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
