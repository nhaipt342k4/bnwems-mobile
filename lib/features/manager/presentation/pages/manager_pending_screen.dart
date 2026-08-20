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

  Color _getStatusBgColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('UNPAID') || s.contains('CHƯA THANH TOÁN')) {
      return const Color(0xFFFEE2E2); // Soft red for unpaid
    }
    if (s.contains('PENDING') || s.contains('CHỜ HOÀN KHO') || s.contains('CHỜ XÁC NHẬN') || s.contains('CHỜ')) {
      return const Color(0xFFFEF3C7); // Soft amber for pending
    }
    if (s.contains('APPROVED') || s.contains('CONFIRMED') || s.contains('ĐÃ')) {
      return const Color(0xFFE0F2FE); // Soft blue for confirmed
    }
    return const Color(0xFFF1F5F9);
  }

  Color _getStatusTextColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('UNPAID') || s.contains('CHƯA THANH TOÁN')) {
      return const Color(0xFFDC2626);
    }
    if (s.contains('PENDING') || s.contains('CHỜ HOÀN KHO') || s.contains('CHỜ XÁC NHẬN') || s.contains('CHỜ')) {
      return const Color(0xFFD97706);
    }
    if (s.contains('APPROVED') || s.contains('CONFIRMED') || s.contains('ĐÃ')) {
      return const Color(0xFF0284C7);
    }
    return const Color(0xFF475569);
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
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'DUYỆT YÊU CẦU',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLabel,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mục chờ xử lý',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.warmTextDark,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      final unreadCount = notifProvider.unreadCount;
                      return Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => context.push('/manager/notifications'),
                              icon: const Icon(LucideIcons.bell, color: Color(0xFF2C241E), size: 20),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Category Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
            const SizedBox(height: 8),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.goldPrimary,
                onRefresh: () => provider.fetchPendingSummary(),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                    : provider.errorMessage != null
                        ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
                        : totalCount == 0
                            ? const Center(child: Text('Không có nội dung chờ xử lý.', style: TextStyle(color: AppColors.warmTextMuted)))
                            : ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                                children: [
                                  // 1. Return Reports (Thu hồi kho)
                                  if (provider.category == PendingCategory.all || provider.category == PendingCategory.returnReport)
                                    ...summary.returnReports.map((report) {
                                      final statusText = Formatters.formatReturnStatus(report.status);
                                      return _buildPendingCard(
                                        onTap: () => context.push('/manager/returns/${report.reportId}'),
                                        typeLabel: 'THU HỒI THIẾT BỊ',
                                        statusText: statusText,
                                        title: '${report.items.length} loại thiết bị thu hồi',
                                        subtitle: 'Người nộp: ${report.reportedBy.fullName} · ${Formatters.formatDateTime(report.createdAt)}',
                                      );
                                    }),

                                  // 2. Deposits (Đặt cọc)
                                  if (provider.category == PendingCategory.all || provider.category == PendingCategory.deposit)
                                    ...summary.deposits.map((deposit) {
                                      final statusText = Formatters.formatPaymentStatus(deposit.status);
                                      return _buildPendingCard(
                                        onTap: () => context.push('/manager/deposits/${deposit.orderId}'),
                                        typeLabel: 'ĐẶT CỌC CHỜ XÁC NHẬN',
                                        statusText: statusText,
                                        title: Formatters.formatOrderEvent(deposit.orderCode, deposit.eventName ?? deposit.customerName),
                                        subtitle: deposit.customerName ?? '',
                                        amount: deposit.amount,
                                      );
                                    }),

                                  // 3. Settlements (Quyết toán)
                                  if (provider.category == PendingCategory.all || provider.category == PendingCategory.settlement)
                                    ...summary.settlements.map((settlement) {
                                      final statusText = Formatters.formatPaymentStatus(settlement.status);
                                      return _buildPendingCard(
                                        onTap: () => context.push('/manager/settlements/${settlement.orderId}'),
                                        typeLabel: 'QUYẾT TOÁN CHỜ XÁC NHẬN',
                                        statusText: statusText,
                                        title: Formatters.formatOrderEvent(settlement.orderCode, settlement.eventName ?? settlement.customerName),
                                        subtitle: settlement.customerName ?? '',
                                        amount: settlement.finalAmount,
                                      );
                                    }),

                                  // 4. Change Requests (Đổi thiết bị)
                                  if (provider.category == PendingCategory.all || provider.category == PendingCategory.changeRequest)
                                    ...summary.changeRequests.map((req) {
                                      final statusText = Formatters.formatChangeRequestStatus(req.status);
                                      return _buildPendingCard(
                                        onTap: () => context.push('/manager/change-requests'),
                                        typeLabel: 'YÊU CẦU ĐỔI THIẾT BỊ',
                                        statusText: statusText,
                                        title: Formatters.formatOrderEvent(req.orderCode, req.eventName),
                                        subtitle: '${req.customerName} · ${Formatters.formatChangeType(req.type)}',
                                        amount: req.amount,
                                        isSignedAmount: true,
                                      );
                                    }),

                                  // 5. Surveys (Khảo sát)
                                  if (provider.category == PendingCategory.all || provider.category == PendingCategory.survey)
                                    ...summary.surveys.map((s) {
                                      final busy = provider.busyId == s.surveyId;
                                      return _buildSurveyCard(
                                        survey: s,
                                        busy: busy,
                                        onApprove: () => provider.confirmSurvey(s.surveyId),
                                      );
                                    }),
                                  const SizedBox(height: 16),
                                ],
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard({
    required VoidCallback onTap,
    required String typeLabel,
    required String statusText,
    required String title,
    required String subtitle,
    double? amount,
    bool isSignedAmount = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Label Badge + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLabel,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(statusText),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(statusText),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C241E),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
              ),
            ],

            // Amount Section if present
            if (amount != null) ...[
              const SizedBox(height: 12),
              const CustomDottedLine(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SỐ TIỀN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${isSignedAmount && amount >= 0 ? '+' : ''}${Formatters.formatCurrency(amount)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC59B63),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard({
    required dynamic survey,
    required bool busy,
    required VoidCallback onApprove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KHẢO SÁT CHỜ XÁC NHẬN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldLabel, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Chờ xác nhận',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatOrderEvent(survey.orderCode, survey.eventName ?? survey.customerName),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Người khảo sát: ${survey.surveyorName ?? '--'} · ${Formatters.formatDate(survey.surveyDate)}',
            style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A359),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Xác nhận khảo sát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ManagerPendingProvider provider, PendingCategory cat, String label) {
    final isSelected = provider.category == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => provider.setCategory(cat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4A359) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: const Color(0xFFEFE8DC)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4A359).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.warmTextDark,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDottedLine extends StatelessWidget {
  const CustomDottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEFE8DC)),
              ),
            );
          }),
        );
      },
    );
  }
}
