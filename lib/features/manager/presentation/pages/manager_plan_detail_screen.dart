import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/manager_schedule_plan.dart';
import '../../data/models/deposit.dart';
import '../../data/models/settlement.dart';
import '../../data/models/collected_equipment_report.dart';
import '../../data/models/change_request.dart';
import '../providers/manager_plan_detail_provider.dart';

/// Manager tap 1 công việc trên lịch → xem báo cáo staff đã nhập cho đơn của công việc đó + DUYỆT tại chỗ.
class ManagerPlanDetailScreen extends StatefulWidget {
  final String planId;
  const ManagerPlanDetailScreen({super.key, required this.planId});

  @override
  State<ManagerPlanDetailScreen> createState() => _ManagerPlanDetailScreenState();
}

class _ManagerPlanDetailScreenState extends State<ManagerPlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerPlanDetailProvider>().load(widget.planId);
    });
  }

  // (bg, fg) theo nhóm màu trạng thái.
  ({Color bg, Color fg}) _tone(String kind) {
    switch (kind) {
      case 'ok':
        return (bg: AppColors.completedBg, fg: AppColors.completedText);
      case 'warn':
        return (bg: AppColors.inProgressBg, fg: AppColors.inProgressText);
      case 'danger':
        return (bg: AppColors.cancelledBg, fg: AppColors.cancelledText);
      case 'info':
        return (bg: AppColors.confirmedBg, fg: AppColors.confirmedText);
      default:
        return (bg: AppColors.pendingBg, fg: AppColors.pendingText);
    }
  }

  Future<void> _act(Future<bool> Function() action, String successMsg) async {
    final ok = await action();
    if (!mounted) return;
    final err = context.read<ManagerPlanDetailProvider>().actionError;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? successMsg : (err ?? 'Thao tác thất bại')),
      backgroundColor: ok ? AppColors.completedText : Colors.red.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerPlanDetailProvider>();
    final plan = provider.plan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => context.pop()),
        title: Text(plan?.taskName ?? 'Chi tiết công việc', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red.shade700))))
              : plan == null
                  ? const Center(child: Text('Không tìm thấy công việc.'))
                  : RefreshIndicator(
                      onRefresh: () => provider.load(widget.planId),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _planHeader(plan),
                          const SizedBox(height: 20),
                          _depositsSection(provider),
                          _settlementSection(provider, plan),
                          _returnsSection(provider),
                          _changeRequestsSection(provider),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Báo cáo khảo sát & biên bản bàn giao sẽ bổ sung sau',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  // ---------------- Header ----------------
  Widget _planHeader(ManagerSchedulePlan plan) {
    final tone = _tone(_statusKind(plan.status));
    final loc = plan.location ?? plan.orderLocation;
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(plan.planCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              _pill(Formatters.formatStatus(plan.status), tone.bg, tone.fg),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.taskName ?? 'Kế hoạch', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.hash, '${plan.orderCode ?? ''}${plan.eventName != null && plan.eventName!.isNotEmpty ? ' · ${plan.eventName}' : ''}', color: AppColors.primary, bold: true),
          if (plan.customerName != null && plan.customerName!.isNotEmpty) ...[const SizedBox(height: 6), _infoRow(LucideIcons.user, plan.customerName!)],
          const SizedBox(height: 6),
          _infoRow(LucideIcons.clock, '${Formatters.formatDate(plan.startTime)} · ${Formatters.formatTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}'),
          if (loc != null && loc.isNotEmpty) ...[const SizedBox(height: 6), _infoRow(LucideIcons.mapPin, loc)],
          if (plan.assignees != null && plan.assignees!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),
            const Text('Nhân sự phụ trách', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ...plan.assignees!.map((a) {
              final isLead = a.role == 'LEAD';
              final checkedIn = a.checkInAt != null && a.checkInAt!.isNotEmpty;
              final checkedOut = a.checkOutAt != null && a.checkOutAt!.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(isLead ? LucideIcons.userCheck : LucideIcons.user, size: 14, color: isLead ? AppColors.leaderPurple : Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${a.fullName}${isLead ? ' · Trưởng nhóm' : ''}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                    if (checkedOut)
                      _pill('Đã check-out', _tone('ok').bg, _tone('ok').fg)
                    else if (checkedIn)
                      _pill('Đã check-in', _tone('info').bg, _tone('info').fg)
                    else
                      _pill('Chưa check-in', _tone('neutral').bg, _tone('neutral').fg),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------------- Cọc ----------------
  Widget _depositsSection(ManagerPlanDetailProvider p) {
    if (p.deposits.isEmpty) return const SizedBox.shrink();
    return _section(LucideIcons.wallet, 'Đặt cọc (staff ghi nhận)', p.deposits.length, [
      for (final d in p.deposits) _depositCard(p, d),
    ]);
  }

  Widget _depositCard(ManagerPlanDetailProvider p, Deposit d) {
    final isUnpaid = d.status == 'UNPAID';
    final tone = _tone(isUnpaid ? 'warn' : (d.status == 'PAID' ? 'ok' : 'danger'));
    final label = d.status == 'UNPAID' ? 'Chờ xác nhận' : (d.status == 'PAID' ? 'Đã thu' : 'Đã hủy');
    return _card([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(Formatters.formatCurrency(d.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          _pill(label, tone.bg, tone.fg),
        ],
      ),
      if (d.paymentMethod != null) ...[const SizedBox(height: 4), _infoRow(LucideIcons.creditCard, _methodLabel(d.paymentMethod))],
      if (d.notes != null && d.notes!.isNotEmpty) ...[const SizedBox(height: 4), _infoRow(LucideIcons.stickyNote, d.notes!)],
      if (isUnpaid) ...[
        const SizedBox(height: 10),
        _primaryAction(p, d.depositId, LucideIcons.checkCircle2, 'Xác nhận đã thu cọc',
            () => _act(() => p.confirmDeposit(d.depositId), 'Đã xác nhận thu cọc')),
      ],
    ]);
  }

  // ---------------- Quyết toán ----------------
  Widget _settlementSection(ManagerPlanDetailProvider p, ManagerSchedulePlan plan) {
    final s = p.settlement;
    return _section(LucideIcons.receipt, 'Quyết toán', s == null ? 0 : 1, [
      if (s == null)
        _card([
          const Text('Chưa có biên bản quyết toán.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          _secondaryAction(LucideIcons.arrowRight, 'Mở màn quyết toán', () => context.push('/manager/settlements/${plan.orderId}')),
        ])
      else
        _settlementCard(s, plan),
    ]);
  }

  Widget _settlementCard(Settlement s, ManagerSchedulePlan plan) {
    final isPaid = s.status == 'PAID';
    final tone = _tone(isPaid ? 'ok' : 'warn');
    return _card([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tổng quyết toán', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          _pill(isPaid ? 'Đã quyết toán' : 'Chờ xác nhận', tone.bg, tone.fg),
        ],
      ),
      const SizedBox(height: 4),
      Text(Formatters.formatCurrency(s.finalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      _kv('Phụ thu phát sinh', Formatters.formatCurrency(s.additionalFee)),
      _kv('Bồi thường hỏng/mất', Formatters.formatCurrency(s.compensation)),
      _kv('Giảm trừ', '- ${Formatters.formatCurrency(s.discount)}'),
      const SizedBox(height: 10),
      _secondaryAction(LucideIcons.arrowRight, isPaid ? 'Xem chi tiết quyết toán' : 'Mở để xác nhận thu nốt',
          () => context.push('/manager/settlements/${plan.orderId}')),
    ]);
  }

  // ---------------- Thu hồi ----------------
  Widget _returnsSection(ManagerPlanDetailProvider p) {
    if (p.returnReports.isEmpty) return const SizedBox.shrink();
    return _section(LucideIcons.packageCheck, 'Thu hồi & hoàn kho', p.returnReports.length, [
      for (final r in p.returnReports) _returnCard(p, r),
    ]);
  }

  Widget _returnCard(ManagerPlanDetailProvider p, CollectedEquipmentReport r) {
    final isSubmitted = r.status == 'SUBMITTED';
    final tone = _tone(isSubmitted ? 'warn' : 'ok');
    final good = r.items.fold<int>(0, (s, i) => s + i.goodQuantity);
    final damaged = r.items.fold<int>(0, (s, i) => s + i.damagedQuantity);
    final lost = r.items.fold<int>(0, (s, i) => s + i.lostQuantity);
    return _card([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(r.reportType == 'SUPPLIER' ? 'Thiết bị thuê NCC' : 'Kho công ty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          _pill(isSubmitted ? 'Chờ xác nhận' : 'Đã hoàn kho', tone.bg, tone.fg),
        ],
      ),
      const SizedBox(height: 8),
      Row(children: [
        _tag('Tốt $good', _tone('ok')),
        const SizedBox(width: 6),
        _tag('Hỏng $damaged', _tone('warn')),
        const SizedBox(width: 6),
        _tag('Mất $lost', _tone('danger')),
      ]),
      const SizedBox(height: 6),
      _infoRow(LucideIcons.user, 'Người nộp: ${r.reportedBy.fullName}'),
      if (isSubmitted) ...[
        const SizedBox(height: 10),
        _primaryAction(p, r.reportId, LucideIcons.checkCircle2, 'Xác nhận hoàn kho',
            () => _act(() => p.confirmReturn(r.reportId), 'Đã xác nhận hoàn kho')),
      ],
    ]);
  }

  // ---------------- Đổi thiết bị ----------------
  Widget _changeRequestsSection(ManagerPlanDetailProvider p) {
    if (p.changeRequests.isEmpty) return const SizedBox.shrink();
    return _section(LucideIcons.repeat, 'Yêu cầu đổi thiết bị', p.changeRequests.length, [
      for (final c in p.changeRequests) _changeCard(p, c),
    ]);
  }

  Widget _changeCard(ManagerPlanDetailProvider p, ChangeRequest c) {
    final isPending = c.status == 'pending';
    final tone = _tone(isPending ? 'warn' : (c.status == 'approved' ? 'ok' : 'danger'));
    final label = isPending ? 'Chờ duyệt' : (c.status == 'approved' ? 'Đã duyệt' : 'Từ chối');
    return _card([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_changeTypeLabel(c.type), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          _pill(label, tone.bg, tone.fg),
        ],
      ),
      const SizedBox(height: 6),
      ...c.items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${it.action == 'add' ? '+ Thêm' : '- Bớt'} ${it.itemName} × ${it.quantity}',
              style: TextStyle(fontSize: 12.5, color: it.action == 'add' ? AppColors.completedText : AppColors.cancelledText),
            ),
          )),
      const SizedBox(height: 4),
      Text('${c.amount >= 0 ? '+' : ''}${Formatters.formatCurrency(c.amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      if (isPending) ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _primaryAction(p, c.changeRequestId, LucideIcons.check, 'Duyệt',
                () => _act(() => p.decideChangeRequest(c.changeRequestId, 'approved'), 'Đã duyệt yêu cầu')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: p.busyId == c.changeRequestId ? null : () => _act(() => p.decideChangeRequest(c.changeRequestId, 'rejected'), 'Đã từ chối yêu cầu'),
              icon: const Icon(LucideIcons.x, size: 15),
              label: const Text('Từ chối'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cancelledText,
                side: BorderSide(color: AppColors.cancelledText.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ],
    ]);
  }

  // ---------------- Building blocks ----------------
  Widget _section(IconData icon, String title, int count, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(999)),
                child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ),
            ],
          ]),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _primaryAction(ManagerPlanDetailProvider p, String id, IconData icon, String label, VoidCallback onTap) {
    final busy = p.busyId == id;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 16),
        label: Text(busy ? 'Đang xử lý…' : label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _secondaryAction(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: color ?? AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: color ?? AppColors.textSecondary))),
    ]);
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _tag(String label, ({Color bg, Color fg}) tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: tone.fg)),
    );
  }

  String _statusKind(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED':
        return 'ok';
      case 'IN_PROGRESS':
        return 'warn';
      case 'CANCELLED':
        return 'danger';
      case 'CONFIRMED':
        return 'info';
      default:
        return 'neutral';
    }
  }

  String _methodLabel(String? m) {
    switch (m) {
      case 'cash':
        return 'Tiền mặt';
      case 'bank_transfer':
        return 'Chuyển khoản';
      default:
        return m ?? '--';
    }
  }

  String _changeTypeLabel(String t) {
    switch (t) {
      case 'add':
        return 'Thêm thiết bị';
      case 'remove':
        return 'Bớt thiết bị';
      case 'replace':
        return 'Thay thế thiết bị';
      default:
        return t;
    }
  }
}
