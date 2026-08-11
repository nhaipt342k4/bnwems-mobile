import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/manager_pending_provider.dart';

class ManagerPendingScreen extends StatefulWidget {
  const ManagerPendingScreen({super.key});

  @override
  State<ManagerPendingScreen> createState() => _ManagerPendingScreenState();
}

class _ManagerPendingScreenState extends State<ManagerPendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerPendingProvider>().fetchPendingSummary();
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerPendingProvider>();
    final summary = provider.summary;

    final returnCount = summary.returnReports.length;
    final depositCount = summary.deposits.length;
    final settlementCount = summary.settlements.length;
    final changeRequestCount = summary.changeRequests.length;
    final surveyCount = summary.surveys.length;
    final totalCount = summary.totalCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mục chờ xử lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final unreadCount = notifProvider.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary),
                    onPressed: () => context.push('/manager/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(provider, PendingCategory.all, 'Tất cả ($totalCount)'),
                  _buildCategoryChip(provider, PendingCategory.returnReport, 'Thu hồi kho ($returnCount)'),
                  _buildCategoryChip(provider, PendingCategory.deposit, 'Đặt cọc ($depositCount)'),
                  _buildCategoryChip(provider, PendingCategory.settlement, 'Quyết toán ($settlementCount)'),
                  _buildCategoryChip(provider, PendingCategory.changeRequest, 'Đổi thiết bị ($changeRequestCount)'),
                  _buildCategoryChip(provider, PendingCategory.survey, 'Khảo sát ($surveyCount)'),
                ],
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchPendingSummary(),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
                      : totalCount == 0
                          ? const Center(child: Text('Không có nội dung chờ xử lý.', style: TextStyle(color: AppColors.textMuted)))
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (provider.category == PendingCategory.all || provider.category == PendingCategory.returnReport)
                                  ...summary.returnReports.map((report) {
                                    return InkWell(
                                      onTap: () => context.push('/manager/returns/${report.reportId}'),
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
                                                const Text('THU HỒI THIẾT BỊ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: Text(
                                                    Formatters.formatReturnStatus(report.status),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text('${report.items.length} loại thiết bị thu hồi', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text('Người nộp: ${report.reportedBy.fullName} · ${Formatters.formatDateTime(report.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                if (provider.category == PendingCategory.all || provider.category == PendingCategory.deposit)
                                  ...summary.deposits.map((deposit) {
                                    return InkWell(
                                      onTap: () => context.push('/manager/deposits/${deposit.orderId}'),
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
                                                const Text('ĐẶT CỌC CHỜ XÁC NHẬN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: Text(
                                                    Formatters.formatPaymentStatus(deposit.status),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(deposit.eventName ?? deposit.customerName ?? deposit.orderCode ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(deposit.customerName ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                            const SizedBox(height: 4),
                                            Text(Formatters.formatCurrency(deposit.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                if (provider.category == PendingCategory.all || provider.category == PendingCategory.settlement)
                                  ...summary.settlements.map((settlement) {
                                    return InkWell(
                                      onTap: () => context.push('/manager/settlements/${settlement.orderId}'),
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
                                                const Text('QUYẾT TOÁN CHỜ XÁC NHẬN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: Text(
                                                    Formatters.formatPaymentStatus(settlement.status),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(settlement.eventName ?? settlement.customerName ?? settlement.orderCode ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(settlement.customerName ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                            const SizedBox(height: 4),
                                            Text(Formatters.formatCurrency(settlement.finalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                if (provider.category == PendingCategory.all || provider.category == PendingCategory.changeRequest)
                                  ...summary.changeRequests.map((req) {
                                    return InkWell(
                                      onTap: () => context.push('/manager/change-requests'),
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
                                                const Text('ĐỔI THIẾT BỊ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: Text(
                                                    Formatters.formatChangeRequestStatus(req.status),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(req.eventName ?? req.orderCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text('${req.customerName} · ${Formatters.formatChangeType(req.type)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                            const SizedBox(height: 4),
                                            Text('${req.amount >= 0 ? '+' : ''}${Formatters.formatCurrency(req.amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                // Khảo sát chờ manager xác nhận — xác nhận ngay tại hàng chờ
                                if (provider.category == PendingCategory.all || provider.category == PendingCategory.survey)
                                  ...summary.surveys.map((s) {
                                    final busy = provider.busyId == s.surveyId;
                                    return Container(
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
                                              const Text('KHẢO SÁT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: AppColors.inProgressBg, borderRadius: BorderRadius.circular(8)),
                                                child: const Text('Chờ xác nhận', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inProgressText)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(s.eventName ?? s.orderCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text('${s.customerName} · ${s.orderCode}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                          const SizedBox(height: 2),
                                          Text('Người nộp: ${s.reportedByName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: busy
                                                  ? null
                                                  : () async {
                                                      final ok = await context.read<ManagerPendingProvider>().confirmSurvey(s.surveyId);
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                        content: Text(ok ? 'Đã xác nhận khảo sát' : (provider.actionError ?? 'Thao tác thất bại')),
                                                        backgroundColor: ok ? AppColors.completedText : Colors.red.shade700,
                                                      ));
                                                    },
                                              icon: busy
                                                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : const Icon(LucideIcons.checkCircle2, size: 16),
                                              label: Text(busy ? 'Đang xử lý…' : 'Xác nhận khảo sát', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ManagerPendingProvider provider, PendingCategory cat, String label) {
    final isSelected = provider.category == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => provider.setCategory(cat),
      ),
    );
  }
}
