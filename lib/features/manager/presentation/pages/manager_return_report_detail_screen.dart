import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/manager_return_report_detail_provider.dart';

class ManagerReturnReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ManagerReturnReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ManagerReturnReportDetailScreen> createState() => _ManagerReturnReportDetailScreenState();
}

class _ManagerReturnReportDetailScreenState extends State<ManagerReturnReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerReturnReportDetailProvider>().loadDetail(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerReturnReportDetailProvider>();
    final report = provider.report;
    final totals = provider.totals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hoàn kho — ${report?.orderCode ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700)))
              : report == null
                  ? const Center(child: Text('Không tìm thấy dữ liệu phiếu hoàn kho.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Dark Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(report.orderCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: provider.isConfirmed ? Colors.green.shade900 : Colors.blue.shade900,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        Formatters.formatReturnStatus(report.status),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: provider.isConfirmed ? Colors.green.shade300 : Colors.blue.shade300),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  report.eventName ?? report.orderCode,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Người nộp: ${report.reportedBy.fullName} · ${Formatters.formatDateTime(report.createdAt)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                                ),
                                if (provider.isConfirmed && report.confirmedBy != null) ...[
                                  const SizedBox(height: 10),
                                  const Divider(color: Colors.white24, height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.checkCircle2, size: 14, color: Colors.green.shade400),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Đã hoàn kho — xác nhận bởi ${report.confirmedBy!.fullName}',
                                          style: TextStyle(fontSize: 12, color: Colors.green.shade400, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Rule Notice Collapsible Banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => provider.toggleNotice(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(LucideIcons.info, size: 16, color: Colors.blue.shade800),
                                          const SizedBox(width: 8),
                                          Text('Lưu ý quy tắc cập nhật tồn kho', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                        ],
                                      ),
                                      Icon(provider.showNotice ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.blue.shade800),
                                    ],
                                  ),
                                ),
                                if (provider.showNotice) ...[
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Text('• Khả dụng: Tồn hiện tại + Số lượng nguyên vẹn', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                  Text('• Tồn hỏng: Tồn hỏng hiện tại + Số lượng hỏng', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                  Text('• Tổng số lượng: Tổng hiện tại - Số lượng mất', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 3 KPI Summary Cards Grid
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade100),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('NGUYÊN VẸN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                      const SizedBox(height: 2),
                                      Text(totals['good'].toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade100),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('HỎNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                      const SizedBox(height: 2),
                                      Text(totals['damaged'].toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('MẤT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                      const SizedBox(height: 2),
                                      Text(totals['lost'].toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Integrated Items Container
                          Container(
                            padding: const EdgeInsets.all(16),
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
                                    const Text('Chi tiết thiết bị hoàn kho', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text('${report.items.length} thiết bị', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Column(
                                  children: report.items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final before = provider.inventoryByItem[item.itemId];

                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: idx == report.items.length - 1 ? Colors.transparent : Colors.grey.shade200)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${idx + 1}. ${item.itemName}',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                ),
                                              ),
                                              Text('ĐV: ${item.unit}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                                child: Text('${item.goodQuantity} Nguyên vẹn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                              ),
                                              if (item.damagedQuantity > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                                                  child: Text('${item.damagedQuantity} Hỏng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                                ),
                                              if (item.lostQuantity > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                                  child: Text('${item.lostQuantity} Mất', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                                ),
                                            ],
                                          ),
                                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text('Ghi chú: ${item.notes}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.amber.shade900)),
                                          ],
                                          if (before != null && !provider.isConfirmed) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tồn kho hiện tại: ${before.quantityAvailable} ➔ Sau hoàn: ${before.quantityAvailable + item.goodQuantity}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (!provider.isConfirmed)
                            ElevatedButton(
                              onPressed: provider.isConfirming ? null : () => provider.confirmReturnReport(widget.reportId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: provider.isConfirming
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Xác nhận hoàn kho', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.checkCircle2, size: 18, color: Colors.green.shade800),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Đã xác nhận hoàn kho ngày ${Formatters.formatDate(report.confirmedAt ?? report.createdAt)}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
