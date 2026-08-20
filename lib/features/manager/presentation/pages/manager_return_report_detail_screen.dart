import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  String _cleanTitle(String? orderCode, String? rawName, String fallback) {
    final code = (orderCode ?? '').trim();
    var name = (rawName ?? fallback).trim();
    if (code.isNotEmpty) {
      name = name.replaceAll(RegExp(r'\s*[-·]\s*' + RegExp.escape(code), caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'^' + RegExp.escape(code) + r'\s*[-·]\s*', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\b' + RegExp.escape(code) + r'\b', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
      name = name.replaceAll(RegExp(r'^[-·\s]+|[-·\s]+$'), '').trim();
    }
    return name.isNotEmpty ? name : 'Kịch bản sự kiện';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerReturnReportDetailProvider>();
    final report = provider.report;
    final totals = provider.totals;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF2C241E)),
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Hoàn kho — ${report?.orderCode ?? ''}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C241E),
            fontFamily: 'serif',
          ),
        ),
        centerTitle: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))))
              : report == null
                  ? const Center(child: Text('Không tìm thấy dữ liệu phiếu hoàn kho.', style: TextStyle(color: AppColors.warmTextMuted)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Soft Warm Gold Metallic Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC59B63), Color(0xFFA87E46)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC59B63).withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      report.orderCode,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF7EEDD)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: provider.isConfirmed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        Formatters.formatReturnStatus(report.status),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: provider.isConfirmed ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _cleanTitle(report.orderCode, report.eventName, report.orderCode),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Người nộp: ${report.reportedBy.fullName} · ${Formatters.formatDateTime(report.createdAt)}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFE8DCCB)),
                                ),
                                if (provider.isConfirmed && report.confirmedBy != null) ...[
                                  const SizedBox(height: 12),
                                  Container(height: 1, color: const Color(0xFF9E876B)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.checkCircle, size: 15, color: Color(0xFF86EFAC)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Đã hoàn kho — xác nhận bởi ${report.confirmedBy!.fullName}',
                                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF86EFAC), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2. Amber Notice Accordion Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9EE),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF0DFBD)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => provider.toggleNotice(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(LucideIcons.info, size: 18, color: Color(0xFFC59B63)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Lưu ý quy tắc cập nhật tồn kho',
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF5C4E43)),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        provider.showNotice ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                        size: 18,
                                        color: const Color(0xFF8C7B6B),
                                      ),
                                    ],
                                  ),
                                ),
                                if (provider.showNotice) ...[
                                  const SizedBox(height: 10),
                                  Container(height: 1, color: const Color(0xFFF0DFBD)),
                                  const SizedBox(height: 10),
                                  const Text('• Khả dụng: Tồn hiện tại + Số lượng nguyên vẹn', style: TextStyle(fontSize: 12.5, color: Color(0xFF5C4E43), height: 1.4)),
                                  const Text('• Tồn hỏng: Tồn hỏng hiện tại + Số lượng hỏng', style: TextStyle(fontSize: 12.5, color: Color(0xFF5C4E43), height: 1.4)),
                                  const Text('• Tổng số lượng: Tổng hiện tại - Số lượng mất', style: TextStyle(fontSize: 12.5, color: Color(0xFF5C4E43), height: 1.4)),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. KPI Stat Tiles (3 Tiles Grid)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFDCFCE7)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('NGUYÊN VẸN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(totals['good'].toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFEF3C7)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('HỎNG HÓC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706), letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(totals['damaged'].toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFEE2E2)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('MẤT MÁT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626), letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(totals['lost'].toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 4. Equipment Details White Surface Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Chi tiết thiết bị hoàn kho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                    Text('${report.items.length} thiết bị', style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted)),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                Column(
                                  children: report.items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final before = provider.inventoryByItem[item.itemId];

                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: idx == report.items.length - 1 ? Colors.transparent : const Color(0xFFEFE8DC),
                                          ),
                                        ),
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
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                                                ),
                                              ),
                                              Text('ĐV: ${item.unit}', style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                                                child: Text('${item.goodQuantity} Nguyên vẹn', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                              ),
                                              if (item.damagedQuantity > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                                                  child: Text('${item.damagedQuantity} Hỏng', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                                ),
                                              if (item.lostQuantity > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                                                  child: Text('${item.lostQuantity} Mất', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                                ),
                                            ],
                                          ),
                                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text('Ghi chú: ${item.notes}', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
                                          ],
                                          if (before != null && !provider.isConfirmed) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Text('Tồn kho hiện tại: ', style: TextStyle(fontSize: 12, color: AppColors.warmTextMuted)),
                                                Text('${before.quantityAvailable}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C241E))),
                                                const Text('  ➔  Sau hoàn: ', style: TextStyle(fontSize: 12, color: Color(0xFFC59B63), fontWeight: FontWeight.bold)),
                                                Text('${before.quantityAvailable + item.goodQuantity}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                              ],
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

                          // 5. Bottom Action Button
                          if (!provider.isConfirmed)
                            ElevatedButton(
                              onPressed: provider.isConfirming ? null : () => provider.confirmReturnReport(widget.reportId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldPrimary,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: provider.isConfirming
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Xác nhận hoàn kho', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.checkCircle, size: 20, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Đã xác nhận hoàn kho ngày ${Formatters.formatDate(report.confirmedAt ?? report.createdAt)}',
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                      textAlign: TextAlign.center,
                                    ),
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
