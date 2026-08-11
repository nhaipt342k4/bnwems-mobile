import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/change_request.dart';
import '../providers/manager_change_requests_provider.dart';

class ManagerChangeRequestsScreen extends StatefulWidget {
  const ManagerChangeRequestsScreen({super.key});

  @override
  State<ManagerChangeRequestsScreen> createState() => _ManagerChangeRequestsScreenState();
}

class _ManagerChangeRequestsScreenState extends State<ManagerChangeRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerChangeRequestsProvider>().fetchRequests();
    });
  }

  void _showDetailBottomSheet(BuildContext context, ChangeRequest request) {
    context.read<ManagerChangeRequestsProvider>().selectRequest(request);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final provider = context.watch<ManagerChangeRequestsProvider>();
        final sel = provider.selectedRequest;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: sel == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chi tiết yêu cầu đổi thiết bị',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đơn hàng ${sel.orderCode} · ${sel.customerName} (${sel.customerPhone})',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    Text(
                      Formatters.formatDateTime(sel.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: sel.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.itemName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  Text(
                                    '${item.action == 'add' ? 'Thêm' : 'Bớt'} · SL ${item.quantity} · ${Formatters.formatCurrency(item.rentalPrice)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thay đổi trên hóa đơn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                          Text(
                            '${sel.amount >= 0 ? '+' : ''}${Formatters.formatCurrency(sel.amount)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),

                    if (provider.actionError != null) ...[
                      const SizedBox(height: 8),
                      Text(provider.actionError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ],

                    const SizedBox(height: 16),

                    if (sel.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: provider.actionLoading
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(ctx);
                                      final success = await context.read<ManagerChangeRequestsProvider>().handleDecision('rejected');
                                      if (success && navigator.canPop()) navigator.pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: provider.actionLoading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Từ chối', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: provider.actionLoading
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(ctx);
                                      final success = await context.read<ManagerChangeRequestsProvider>().handleDecision('approved');
                                      if (success && navigator.canPop()) navigator.pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: provider.actionLoading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Duyệt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerChangeRequestsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyệt đổi thiết bị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchRequests(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
                ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
                : provider.requests.isEmpty
                    ? const Center(child: Text('Không có yêu cầu nào đang chờ duyệt.', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.requests.length,
                        itemBuilder: (context, index) {
                          final req = provider.requests[index];
                          return InkWell(
                            onTap: () => _showDetailBottomSheet(context, req),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          Formatters.formatChangeType(req.type),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          Formatters.formatChangeRequestStatus(req.status),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(req.eventName ?? req.orderCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text('${req.customerName} · ${req.orderCode}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${req.amount >= 0 ? '+' : ''}${Formatters.formatCurrency(req.amount)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
