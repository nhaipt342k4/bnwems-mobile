import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/work_task_models.dart';

class SupplierTransactionSection extends StatelessWidget {
  final List<SupplierTransaction> transactions;
  final Future<void> Function(String transactionId, String stItemId, int receivedQuantity) onReceiveItem;
  /// Xác nhận "đã nhận" cả đơn (Đã duyệt → Đã nhận). null = không cho thao tác (vd màn manager read-only).
  final Future<void> Function(String transactionId)? onConfirmReceived;
  // Chỉ xem (manager review): ẩn nút bút chì cập nhật SL nhận.
  final bool readOnly;

  const SupplierTransactionSection({
    super.key,
    required this.transactions,
    required this.onReceiveItem,
    this.onConfirmReceived,
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
              'Nhận thiết bị từ Nhà cung cấp (Đơn thuê/mua)',
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
                const SizedBox(height: 8),
                _statusBadge(tx.status),
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
                            if (!readOnly && item.receivedQuantity < item.quantity) ...[
                              const SizedBox(width: 8),
                              // Xác nhận nhận ĐỦ dòng hàng này (receivedQuantity = quantity) — thay nút bút cũ
                              // (mở dialog nhập số, không báo lỗi/thành công nên có vẻ "không gửi BE").
                              _ReceiveLineButton(
                                onReceive: () => onReceiveItem(tx.transactionId, item.stItemId, item.quantity),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!readOnly && tx.status == 'APPROVED' && onConfirmReceived != null) ...[
                  const SizedBox(height: 12),
                  _ConfirmReceivedButton(
                    onConfirm: () => onConfirmReceived!(tx.transactionId),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Widget pill(String label, Color bg, Color fg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        );
    switch (status) {
      case 'PENDING':
        return pill('Chờ duyệt', Colors.amber.shade50, Colors.amber.shade800);
      case 'APPROVED':
        return pill('Đã duyệt', Colors.blue.shade50, Colors.blue.shade700);
      case 'RECEIVED':
        return pill('Đã nhận', Colors.green.shade50, Colors.green.shade700);
      case 'COMPLETED':
        return pill('Hoàn thành', Colors.green.shade100, Colors.green.shade800);
      case 'CANCELLED':
        return pill('Đã hủy', Colors.red.shade50, Colors.red.shade700);
      default:
        return pill(status, Colors.grey.shade100, Colors.grey.shade700);
    }
  }

}

// Nút "Xác nhận đã nhận" (Đã duyệt → Đã nhận) — có hỏi xác nhận + loading + báo kết quả. Tách stateful để
// quản lý loading vì SupplierTransactionSection là StatelessWidget.
class _ConfirmReceivedButton extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const _ConfirmReceivedButton({required this.onConfirm});

  @override
  State<_ConfirmReceivedButton> createState() => _ConfirmReceivedButtonState();
}

class _ConfirmReceivedButtonState extends State<_ConfirmReceivedButton> {
  bool _loading = false;

  Future<void> _run() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận'),
        content: const Text('Xác nhận đã nhận toàn bộ đơn này từ nhà cung cấp? Trạng thái sẽ chuyển sang "Đã nhận".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Lấy messenger trước await: sau khi xác nhận, màn hình reload (_loadData) có thể gỡ nút khỏi cây.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
      messenger.showSnackBar(
        SnackBar(content: const Text('Đã xác nhận nhận hàng'), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể xác nhận: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _run,
        icon: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(LucideIcons.packageCheck, size: 18),
        label: Text(_loading ? 'Đang xác nhận...' : 'Xác nhận đã nhận'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// Nút "Xác nhận" cho TỪNG DÒNG hàng — đánh dấu dòng đã nhận đủ (receivedQuantity = quantity) + báo
// thành công/lỗi rõ ràng (thay nút bút cũ vốn im lặng). Stateful để có loading riêng cho từng dòng.
class _ReceiveLineButton extends StatefulWidget {
  final Future<void> Function() onReceive;

  const _ReceiveLineButton({required this.onReceive});

  @override
  State<_ReceiveLineButton> createState() => _ReceiveLineButtonState();
}

class _ReceiveLineButtonState extends State<_ReceiveLineButton> {
  bool _loading = false;

  Future<void> _run() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.onReceive();
      messenger.showSnackBar(
        SnackBar(content: const Text('Đã xác nhận nhận dòng hàng'), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể xác nhận: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: _loading ? null : _run,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _loading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Xác nhận'),
      ),
    );
  }
}
