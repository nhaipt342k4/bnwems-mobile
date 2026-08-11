import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/work_task_models.dart';
import '../../data/services/change_request_api_service.dart';

/// Bottom sheet cho LEAD gửi yêu cầu đổi thiết bị tại hiện trường (add/remove/replace).
class ChangeRequestFormSheet extends StatefulWidget {
  final String orderId;
  final List<WorkTaskItem> orderItems; // thiết bị đang có trong đơn (để BỚT / đồ cũ khi THAY)
  final VoidCallback? onSubmitted;

  const ChangeRequestFormSheet({
    super.key,
    required this.orderId,
    required this.orderItems,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required List<WorkTaskItem> orderItems,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeRequestFormSheet(orderId: orderId, orderItems: orderItems, onSubmitted: onSubmitted),
    );
  }

  @override
  State<ChangeRequestFormSheet> createState() => _ChangeRequestFormSheetState();
}

class _ChangeRequestFormSheetState extends State<ChangeRequestFormSheet> {
  final _service = ChangeRequestApiService();

  String _type = 'remove'; // 'add' | 'remove' | 'replace'
  String? _oldItemId; // remove / replace-old (từ orderItems)
  String? _newItemId; // add / replace-new (từ catalog)
  final _oldQtyCtrl = TextEditingController(text: '1');
  final _newQtyCtrl = TextEditingController(text: '1');

  List<WorkTaskItem> _catalog = [];
  bool _loadingCatalog = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orderItems.isNotEmpty) _oldItemId = widget.orderItems.first.itemId;
    _service.listCatalog().then((rows) {
      if (mounted) {
        setState(() {
          _catalog = rows;
          if (rows.isNotEmpty) _newItemId = rows.first.itemId;
          _loadingCatalog = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loadingCatalog = false);
    });
  }

  @override
  void dispose() {
    _oldQtyCtrl.dispose();
    _newQtyCtrl.dispose();
    super.dispose();
  }

  bool get _needsOld => _type == 'remove' || _type == 'replace';
  bool get _needsNew => _type == 'add' || _type == 'replace';

  Future<void> _submit() async {
    final items = <ChangeRequestItemInput>[];
    if (_needsOld) {
      final q = int.tryParse(_oldQtyCtrl.text) ?? 0;
      if (_oldItemId == null || q <= 0) {
        setState(() => _error = 'Chọn thiết bị cần bớt và số lượng hợp lệ.');
        return;
      }
      items.add(ChangeRequestItemInput(catalogItemId: _oldItemId!, quantity: q, action: 'remove'));
    }
    if (_needsNew) {
      final q = int.tryParse(_newQtyCtrl.text) ?? 0;
      if (_newItemId == null || q <= 0) {
        setState(() => _error = 'Chọn thiết bị cần thêm và số lượng hợp lệ.');
        return;
      }
      items.add(ChangeRequestItemInput(catalogItemId: _newItemId!, quantity: q, action: 'add'));
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.create(widget.orderId, type: _type, items: items);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu đổi thiết bị cho Quản lý duyệt.'), backgroundColor: AppColors.completedText),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Row(
                children: [
                  Icon(LucideIcons.replace, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Yêu cầu đổi thiết bị (hiện trường)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Loại yêu cầu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _typeChip('remove', 'Bớt'),
                  const SizedBox(width: 8),
                  _typeChip('add', 'Thêm'),
                  const SizedBox(width: 8),
                  _typeChip('replace', 'Thay thế'),
                ],
              ),
              const SizedBox(height: 16),

              if (_needsOld) ...[
                Text(_type == 'replace' ? 'Thiết bị cũ (bỏ ra)' : 'Thiết bị cần bớt', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _dropdown(
                  value: _oldItemId,
                  items: widget.orderItems.map((i) => DropdownMenuItem(value: i.itemId, child: Text('${i.name} (đang có ${i.quantity})', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _oldItemId = v),
                  hint: 'Chọn từ thiết bị trong đơn',
                ),
                const SizedBox(height: 8),
                _qtyField(_oldQtyCtrl, 'Số lượng bớt'),
                const SizedBox(height: 16),
              ],

              if (_needsNew) ...[
                Text(_type == 'replace' ? 'Thiết bị mới (thay vào)' : 'Thiết bị cần thêm', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (_loadingCatalog)
                  const Padding(padding: EdgeInsets.all(8), child: Text('Đang tải danh mục thiết bị...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                else
                  _dropdown(
                    value: _newItemId,
                    items: _catalog.map((i) => DropdownMenuItem(value: i.itemId, child: Text('${i.name}${i.quantityAvailable != null ? ' (khả dụng ${i.quantityAvailable})' : ''}', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _newItemId = v),
                    hint: 'Chọn từ danh mục thiết bị',
                  ),
                const SizedBox(height: 8),
                _qtyField(_newQtyCtrl, 'Số lượng thêm'),
                const SizedBox(height: 16),
              ],

              if (_error != null) ...[
                Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
                const SizedBox(height: 10),
              ],
              AppButton(
                text: 'Gửi yêu cầu cho Quản lý',
                isFullWidth: true,
                isLoading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _type == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: selected,
        onSelected: (_) => setState(() {
          _type = value;
          _error = null;
        }),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _qtyField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
