import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/work_task_models.dart';

class SupplierTransactionSection extends StatelessWidget {
  final List<SupplierTransaction> transactions;
  final Future<void> Function(String transactionId, String stItemId, int receivedQuantity) onReceiveItem;
  final Future<void> Function(String transactionId)? onConfirmReceived;
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
            Icon(LucideIcons.truck, size: 18, color: Color(0xFF7E22CE)),
            SizedBox(width: 8),
            Text(
              'Nhận thiết bị từ Nhà cung cấp (Đơn thuê/mua)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...transactions.map(
          (tx) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tx.supplierName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                    Text(tx.transactionCode, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.warmTextMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(tx.serviceTitle, style: const TextStyle(fontSize: 13, color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
                Text('Chi phí dự kiến: ${Formatters.formatCurrency(tx.estimatedCost)}', style: const TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                const SizedBox(height: 8),
                _statusBadge(tx.status),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                ),

                const Text('Danh sách hạng mục thuê:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark)),
                const SizedBox(height: 8),
                ...tx.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0DFBD)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.itemName} (${item.quantity} cái)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warmTextDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đã nhận: ${item.receivedQuantity}/${item.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.receivedQuantity >= item.quantity ? const Color(0xFF16A34A) : AppColors.goldLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!readOnly && item.receivedQuantity < item.quantity) ...[
                          const SizedBox(width: 8),
                          _ReceiveLineButton(
                            onReceive: () => onReceiveItem(tx.transactionId, item.stItemId, item.quantity),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!readOnly && tx.status == 'APPROVED' && onConfirmReceived != null) ...[
                  const SizedBox(height: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        );
    switch (status) {
      case 'PENDING':
        return pill('Chờ duyệt', const Color(0xFFFFF9EE), const Color(0xFFD97706));
      case 'APPROVED':
        return pill('Đã duyệt', const Color(0xFFF7F2EA), AppColors.goldLabel);
      case 'RECEIVED':
        return pill('Đã nhận', const Color(0xFFF0FDF4), const Color(0xFF16A34A));
      case 'COMPLETED':
        return pill('Hoàn thành', const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case 'CANCELLED':
        return pill('Đã hủy', const Color(0xFFFEF2F2), const Color(0xFFB91C1C));
      default:
        return pill(status, const Color(0xFFF7F2EA), AppColors.goldLabel);
    }
  }
}

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đã nhận', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Xác nhận đã nhận toàn bộ đơn này từ nhà cung cấp? Trạng thái sẽ chuyển sang "Đã nhận".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: AppColors.warmTextMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: Colors.white),
            child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xác nhận nhận hàng'), backgroundColor: Color(0xFF16A34A)),
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
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _run,
        icon: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(LucideIcons.packageCheck, size: 18),
        label: Text(_loading ? 'Đang xác nhận...' : 'Xác nhận đã nhận', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}

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
        const SnackBar(content: Text('Đã xác nhận nhận dòng hàng'), backgroundColor: Color(0xFF16A34A)),
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
      height: 32,
      child: ElevatedButton(
        onPressed: _loading ? null : _run,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Xác nhận'),
      ),
    );
  }
}
