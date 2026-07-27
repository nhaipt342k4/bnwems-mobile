import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_return_reports_provider.dart';

class ManagerReturnReportsScreen extends StatefulWidget {
  const ManagerReturnReportsScreen({super.key});

  @override
  State<ManagerReturnReportsScreen> createState() => _ManagerReturnReportsScreenState();
}

class _ManagerReturnReportsScreenState extends State<ManagerReturnReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerReturnReportsProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerReturnReportsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác nhận hoàn kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchReports(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
                ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
                : provider.reports.isEmpty
                    ? const Center(child: Text('Chưa có phiếu hoàn kho nào.', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.reports.length,
                        itemBuilder: (context, index) {
                          final report = provider.reports[index];
                          final isConfirmed = report.status == 'CONFIRMED';

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
                                      Text(report.orderCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isConfirmed ? Colors.green.shade50 : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          Formatters.formatReturnStatus(report.status),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isConfirmed ? Colors.green.shade800 : Colors.blue.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${report.items.length} loại thiết bị thu hồi',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Người nộp: ${report.reportedBy.fullName} · ${Formatters.formatDateTime(report.createdAt)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
