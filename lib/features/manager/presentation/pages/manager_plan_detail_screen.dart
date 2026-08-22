import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../tasks/data/models/work_task_models.dart';
import '../../../tasks/data/services/collected_report_api_service.dart';
import '../../../tasks/data/services/deposit_api_service.dart';
import '../../../tasks/data/services/evidence_api_service.dart';
import '../../../tasks/data/services/inventory_api_service.dart';
import '../../../tasks/data/services/schedule_plan_api_service.dart';
import '../../../tasks/data/services/settlement_api_service.dart';
import '../../../tasks/data/services/supplier_transaction_api_service.dart';
import '../../../tasks/data/services/survey_report_api_service.dart';
import '../../../tasks/presentation/widgets/equipment_table.dart';
import '../../../tasks/presentation/widgets/field_payment_section.dart';
import '../../../tasks/presentation/widgets/supplier_transaction_section.dart';
import '../../../tasks/presentation/widgets/survey_report_section.dart';
import '../../data/models/change_request.dart';
import '../../data/services/manager_change_request_service.dart';
import '../../data/services/manager_deposit_service.dart';
import '../../data/services/manager_inventory_service.dart';
import '../../data/services/manager_survey_service.dart';

/// Manager tap 1 công việc trên lịch → xem ĐÚNG báo cáo Leader Staff đã nhập cho công việc đó (theo taskCode:
/// khảo sát / lắp đặt / thu hồi) + duyệt các mục cần xử lý. Hiển thị đọc-lại bằng chính các section của staff.
class ManagerPlanDetailScreen extends StatefulWidget {
  final String planId;
  // Cho phép inject để preview/test — mặc định dùng service thật.
  final SchedulePlanApiService? planApi;
  final SurveyReportApiService? surveyApi;
  final DepositApiService? depositApi;
  final EvidenceApiService? evidenceApi;
  const ManagerPlanDetailScreen({super.key, required this.planId, this.planApi, this.surveyApi, this.depositApi, this.evidenceApi});

  @override
  State<ManagerPlanDetailScreen> createState() => _ManagerPlanDetailScreenState();
}

class _ManagerPlanDetailScreenState extends State<ManagerPlanDetailScreen> {
  // Staff services (đọc dữ liệu Leader đã nhập) — manager có quyền gọi.
  late final _planService = widget.planApi ?? SchedulePlanApiService();
  final _inventoryService = InventoryApiService();
  final _supplierService = SupplierTransactionApiService();
  late final _surveyService = widget.surveyApi ?? SurveyReportApiService();
  late final _depositService = widget.depositApi ?? DepositApiService();
  final _collectedService = CollectedReportApiService();
  final _settlementService = SettlementApiService();
  late final _evidenceService = widget.evidenceApi ?? EvidenceApiService();
  // Manager services (duyệt/xác nhận theo id).
  final _mgrSurvey = ManagerSurveyService();
  final _mgrInventory = ManagerInventoryService();
  final _mgrChange = ManagerChangeRequestService();
  final _mgrDeposit = ManagerDepositService();

  bool _loading = true;
  String? _error;
  SchedulePlan? _plan;

  List<WorkTaskItem> _items = [];
  List<SupplierTransaction> _supplierTxs = [];
  SurveyReport? _surveyReport;
  String? _surveyId;
  String? _surveyStatus;
  FieldPaymentRecord? _fieldPayment;
  String? _depositId;
  String? _depositStatus;
  CollectedEquipmentReport? _internalCollected;
  CollectedEquipmentReport? _supplierCollected;
  Settlement? _settlement;
  List<ChangeRequest> _changeRequests = [];
  // Ảnh minh chứng đã resolve URL (Leader nộp) — hiện cho Manager xem.
  List<String> _handoverPhotoUrls = [];
  List<String> _settlementPhotoUrls = [];
  List<String> _collectedInternalUrls = [];
  List<String> _collectedSupplierUrls = [];
  final Map<String, String> _checkInUrls = {}; // userId -> fileUrl

  String? _busyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await _planService.getById(widget.planId);
      _plan = plan;
      final code = plan.taskCode;
      final orderId = plan.orderId;
      final futures = <Future<void>>[];

      // Reset ảnh minh chứng để refresh không giữ URL cũ.
      _handoverPhotoUrls = [];
      _settlementPhotoUrls = [];
      _collectedInternalUrls = [];
      _collectedSupplierUrls = [];
      _checkInUrls.clear();

      // Ảnh check-in điểm danh của từng nhân sự (mọi loại việc) — resolve từ checkInEvidenceId.
      for (final a in plan.assignees) {
        final eid = a.checkInEvidenceId;
        if (eid != null && eid.isNotEmpty) {
          futures.add(() async {
            try {
              _checkInUrls[a.userId] = (await _evidenceService.getById(eid)).fileUrl;
            } catch (_) {}
          }());
        }
      }

      if (code == 'SETUP' || code == 'COLLECT') {
        futures.add(_inventoryService.getPicklist(orderId).then((v) => _items = v).catchError((_) => <WorkTaskItem>[]).then((_) {}));
        futures.add(_supplierService.listWithItems(orderId).then((v) => _supplierTxs = v).catchError((_) => <SupplierTransaction>[]).then((_) {}));
      }
      if (code == 'SETUP') {
        futures.add(_mgrChange.getChangeRequests(orderId: orderId).then((v) => _changeRequests = v).catchError((_) => <ChangeRequest>[]).then((_) {}));
        // Ảnh biên bản bàn giao: plan mang evidenceIds (mọi ảnh Leader đã nộp) → resolve thành URL.
        futures.add(() async {
          _handoverPhotoUrls = await _resolveUrls(plan.evidenceIds);
        }());
      }
      if (code == 'SURVEY') {
        futures.add(_surveyService.listByPlanId(plan.planId).then((rows) async {
          if (rows.isNotEmpty) {
            _surveyId = rows.first['surveyId']?.toString();
            _surveyStatus = rows.first['status']?.toString();
            if (_surveyId != null) {
              try {
                // Lấy chi tiết đầy đủ (diện tích/lối vào/evidenceIds) — list chỉ có trường tóm tắt.
                final detail = await _surveyService.getById(_surveyId!);
                final urls = await _resolveUrls(parseEvidenceIds(detail['evidenceIds']));
                _surveyReport = SurveyReport.fromJson(detail, evidencePhotoUrls: urls);
              } catch (_) {}
            }
          }
        }).catchError((_) {}));
        futures.add(_depositService.list(orderId).then((deps) async {
          if (deps.isNotEmpty) {
            final d = deps.first;
            _depositId = d['depositId']?.toString();
            _depositStatus = d['status']?.toString();
            final urls = await _resolveUrls(parseEvidenceIds(d['evidenceIds']));
            _fieldPayment = FieldPaymentRecord.fromJson(d, evidencePhotoUrl: urls.isEmpty ? null : urls.first);
          }
        }).catchError((_) {}));
      }
      if (code == 'COLLECT') {
        futures.add(_collectedService.listByOrderId(orderId).then((reports) async {
          _internalCollected = reports.cast<CollectedEquipmentReport?>().firstWhere((r) => r?.reportType == 'INTERNAL', orElse: () => null);
          _supplierCollected = reports.cast<CollectedEquipmentReport?>().firstWhere((r) => r?.reportType == 'SUPPLIER', orElse: () => null);
          if (_internalCollected != null) _collectedInternalUrls = await _resolveUrls(_internalCollected!.evidenceIds);
          if (_supplierCollected != null) _collectedSupplierUrls = await _resolveUrls(_supplierCollected!.evidenceIds);
        }).catchError((_) {}));
        futures.add(_settlementService.getByOrderId(orderId).then((s) async {
          _settlement = s;
          if (s != null) _settlementPhotoUrls = await _resolveUrls(s.evidenceIds);
        }).catchError((_) => null).then((_) {}));
      }

      await Future.wait(futures);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirm(String id, Future<void> Function() action, String okMsg) async {
    setState(() => _busyId = id);
    try {
      await action();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMsg), backgroundColor: AppColors.completedText));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // Resolve danh sách evidenceId → fileUrl (bỏ qua id lỗi).
  Future<List<String>> _resolveUrls(List<String> ids) async {
    final urls = <String>[];
    for (final id in ids) {
      try {
        final ev = await _evidenceService.getById(id);
        if (ev.fileUrl.isNotEmpty) urls.add(ev.fileUrl);
      } catch (_) {}
    }
    return urls;
  }

  // Dải ảnh minh chứng cuộn ngang.
  Widget _photoGallery(List<String> urls) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            urls[i],
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(width: 88, height: 88, color: AppColors.background, alignment: Alignment.center, child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (_, _, _) => Container(width: 88, height: 88, color: AppColors.background, alignment: Alignment.center, child: const Icon(LucideIcons.image, size: 18, color: AppColors.textMuted)),
          ),
        ),
      ),
    );
  }

  ({Color bg, Color fg}) _tone(String kind) {
    switch (kind) {
      case 'ok':
        return (bg: AppColors.completedBg, fg: AppColors.completedText);
      case 'warn':
        return (bg: AppColors.inProgressBg, fg: AppColors.inProgressText);
      case 'danger':
        return (bg: AppColors.cancelledBg, fg: AppColors.cancelledText);
      default:
        return (bg: AppColors.confirmedBg, fg: AppColors.confirmedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => context.pop()),
        title: Text(plan?.taskName ?? 'Chi tiết công việc', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: Colors.red.shade700))))
              : plan == null
                  ? const Center(child: Text('Không tìm thấy công việc.'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _planHeader(plan),
                          const SizedBox(height: 18),
                          ..._sectionsForTask(plan.taskCode),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _sectionsForTask(String code) {
    switch (code) {
      case 'SURVEY':
        return _surveySections();
      case 'SETUP':
        return _setupSections();
      case 'COLLECT':
        return _collectSections();
      default:
        return [_emptyHint('Loại công việc này chưa có báo cáo hiển thị.')];
    }
  }

  // ---------------- SURVEY ----------------
  List<Widget> _surveySections() {
    final canConfirmSurvey = _surveyId != null && (_surveyStatus == 'SUBMITTED' || _surveyStatus == 'NEEDS_REVIEW');
    return [
      _sectionTitle(LucideIcons.clipboardList, 'Báo cáo khảo sát hiện trường'),
      if (_surveyReport != null) ...[
        SurveyReportSection(existingReport: _surveyReport, onSubmit: (_) async {}),
        if (canConfirmSurvey) ...[
          const SizedBox(height: 10),
          _primary(_surveyId!, LucideIcons.checkCircle2, 'Xác nhận khảo sát', () => _confirm(_surveyId!, () => _mgrSurvey.confirmSurvey(_surveyId!), 'Đã xác nhận khảo sát')),
        ],
      ] else
        _emptyHint('Leader chưa nộp báo cáo khảo sát.'),
      const SizedBox(height: 20),
      _sectionTitle(LucideIcons.wallet, 'Cọc thu tại hiện trường'),
      if (_fieldPayment != null) ...[
        FieldPaymentSection(existingPayment: _fieldPayment, onSubmit: (_) async {}),
        if (_depositId != null && _depositStatus == 'UNPAID') ...[
          const SizedBox(height: 10),
          _primary(_depositId!, LucideIcons.checkCircle2, 'Xác nhận đã thu cọc', () => _confirm(_depositId!, () => _mgrDeposit.updateDepositStatus(_depositId!, status: 'PAID'), 'Đã xác nhận thu cọc')),
        ],
      ] else
        _emptyHint('Chưa ghi nhận cọc hiện trường.'),
    ];
  }

  // ---------------- SETUP ----------------
  List<Widget> _setupSections() {
    return [
      _sectionTitle(LucideIcons.packageOpen, 'Thiết bị xuất kho'),
      if (_items.isNotEmpty) EquipmentTable(items: _items) else _emptyHint('Chưa có dữ liệu thiết bị.'),
      if (_supplierTxs.isNotEmpty) ...[
        const SizedBox(height: 20),
        SupplierTransactionSection(transactions: _supplierTxs, onReceiveItem: (_, _, _) async {}, readOnly: true),
      ],
      const SizedBox(height: 20),
      _sectionTitle(LucideIcons.fileCheck2, 'Biên bản bàn giao'),
      _handoverCard(),
    ];
  }

  Widget _handoverCard() {
    if (_handoverPhotoUrls.isEmpty) {
      return _emptyHint('Leader chưa gửi ảnh biên bản bàn giao.');
    }
    return _card([
      Text('${_handoverPhotoUrls.length} ảnh biên bản Leader đã nộp', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      _photoGallery(_handoverPhotoUrls),
    ]);
  }

  // ---------------- COLLECT ----------------
  List<Widget> _collectSections() {
    return [
      _sectionTitle(LucideIcons.packageOpen, 'Thiết bị thu hồi'),
      if (_items.isNotEmpty) EquipmentTable(items: _items) else _emptyHint('Chưa có dữ liệu thiết bị.'),
      const SizedBox(height: 20),
      _sectionTitle(LucideIcons.clipboardCheck, 'Báo cáo kiểm đếm thu hồi'),
      if (_internalCollected != null) _collectedCard(_internalCollected!, 'Kho công ty', _collectedInternalUrls) else _emptyHint('Leader chưa nộp báo cáo thu hồi kho công ty.'),
      if (_supplierCollected != null) _collectedCard(_supplierCollected!, 'Thiết bị NCC', _collectedSupplierUrls),
      const SizedBox(height: 20),
      _sectionTitle(LucideIcons.receipt, 'Quyết toán'),
      _settlementCard(),
    ];
  }

  Widget _collectedCard(CollectedEquipmentReport r, String label, List<String> photoUrls) {
    final isSubmitted = r.status == 'SUBMITTED';
    final tone = _tone(isSubmitted ? 'warn' : 'ok');
    final good = r.items.fold<int>(0, (s, i) => s + i.goodQuantity);
    final damaged = r.items.fold<int>(0, (s, i) => s + i.damagedQuantity);
    final lost = r.items.fold<int>(0, (s, i) => s + i.lostQuantity);
    return _card([
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        _pill(isSubmitted ? 'Chờ xác nhận' : 'Đã hoàn kho', tone.bg, tone.fg),
      ]),
      const SizedBox(height: 8),
      ...r.items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(child: Text(it.name, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
              _tag('Tốt ${it.goodQuantity}', _tone('ok')),
              const SizedBox(width: 4),
              _tag('Hỏng ${it.damagedQuantity}', _tone('warn')),
              const SizedBox(width: 4),
              _tag('Mất ${it.lostQuantity}', _tone('danger')),
            ]),
          )),
      const SizedBox(height: 4),
      Text('Tổng: tốt $good · hỏng $damaged · mất $lost', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      if (photoUrls.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('Ảnh minh chứng (${photoUrls.length})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _photoGallery(photoUrls),
      ],
      if (isSubmitted) ...[
        const SizedBox(height: 10),
        _primary(r.reportId, LucideIcons.checkCircle2, 'Xác nhận hoàn kho', () => _confirm(r.reportId, () => _mgrInventory.confirmReturnReport(r.reportId), 'Đã xác nhận hoàn kho')),
      ],
    ]);
  }

  Widget _settlementCard() {
    final s = _settlement;
    if (s == null) {
      return _card([
        const Text('Chưa có biên bản quyết toán.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 10),
        _secondary(LucideIcons.arrowRight, 'Mở màn quyết toán', () => context.push('/manager/settlements/${_plan!.orderId}')),
      ]);
    }
    final isPaid = s.status == 'PAID';
    return _card([
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Tổng quyết toán', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        _pill(isPaid ? 'Đã quyết toán' : 'Chờ xác nhận', _tone(isPaid ? 'ok' : 'warn').bg, _tone(isPaid ? 'ok' : 'warn').fg),
      ]),
      const SizedBox(height: 4),
      Text(Formatters.formatCurrency(s.finalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      _kv('Phụ thu phát sinh', Formatters.formatCurrency(s.additionalFee)),
      _kv('Bồi thường hỏng/mất', Formatters.formatCurrency(s.compensation)),
      _kv('Giảm trừ', '- ${Formatters.formatCurrency(s.discount)}'),
      if (_settlementPhotoUrls.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('Ảnh chứng từ quyết toán (${_settlementPhotoUrls.length})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _photoGallery(_settlementPhotoUrls),
      ],
      const SizedBox(height: 10),
      _secondary(LucideIcons.arrowRight, isPaid ? 'Xem chi tiết quyết toán' : 'Mở để xác nhận thu nốt', () => context.push('/manager/settlements/${_plan!.orderId}')),
    ]);
  }

  Widget _changeCard(ChangeRequest c) {
    final isPending = c.status == 'pending';
    final tone = _tone(isPending ? 'warn' : (c.status == 'approved' ? 'ok' : 'danger'));
    final label = isPending ? 'Chờ duyệt' : (c.status == 'approved' ? 'Đã duyệt' : 'Từ chối');
    return _card([
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_changeType(c.type), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        _pill(label, tone.bg, tone.fg),
      ]),
      const SizedBox(height: 6),
      ...c.items.map((it) => Text('${it.action == 'add' ? '+ Thêm' : '- Bớt'} ${it.itemName} × ${it.quantity}',
          style: TextStyle(fontSize: 12.5, color: it.action == 'add' ? AppColors.completedText : AppColors.cancelledText))),
      const SizedBox(height: 4),
      Text('${c.amount >= 0 ? '+' : ''}${Formatters.formatCurrency(c.amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      if (isPending) ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _primary(c.changeRequestId, LucideIcons.check, 'Duyệt', () => _confirm(c.changeRequestId, () => _mgrChange.approveChangeRequest(c.changeRequestId, 'approved'), 'Đã duyệt yêu cầu'))),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busyId == c.changeRequestId ? null : () => _confirm(c.changeRequestId, () => _mgrChange.approveChangeRequest(c.changeRequestId, 'rejected'), 'Đã từ chối yêu cầu'),
              icon: const Icon(LucideIcons.x, size: 15),
              label: const Text('Từ chối'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.cancelledText, side: BorderSide(color: AppColors.cancelledText.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ]),
      ],
    ]);
  }

  // ---------------- Header + building blocks ----------------
  Widget _planHeader(SchedulePlan plan) {
    final loc = plan.location;
    return Container(
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(plan.planCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE2D5C5))),
          _pill(Formatters.formatStatus(plan.status), const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
        ]),
        const SizedBox(height: 8),
        Text(plan.taskName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        _info(LucideIcons.hash, Formatters.formatOrderEvent(plan.orderCode, plan.eventName), color: const Color(0xFFF3D084), bold: true),
        if (plan.customerName.isNotEmpty) ...[const SizedBox(height: 6), _info(LucideIcons.user, plan.customerName, color: const Color(0xFFD6C5B3))],
        const SizedBox(height: 6),
        _info(LucideIcons.clock, '${Formatters.formatDate(plan.startTime)} · ${Formatters.formatTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}', color: const Color(0xFFD6C5B3)),
        if (loc != null && loc.isNotEmpty) ...[const SizedBox(height: 6), _info(LucideIcons.mapPin, loc, color: const Color(0xFFD6C5B3))],
        if (plan.assignees.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFF6E5644)),
          const SizedBox(height: 12),
          const Text('Nhân sự phụ trách', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB8A594), letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...plan.assignees.map((a) {
            final isLead = a.role == 'LEAD';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(isLead ? LucideIcons.userCheck : LucideIcons.user, size: 14, color: isLead ? const Color(0xFFF3D084) : const Color(0xFFE2D5C5)),
                const SizedBox(width: 6),
                Expanded(child: Text('${a.fullName}${isLead ? ' · Trưởng nhóm' : ''}', style: const TextStyle(fontSize: 13, color: Colors.white))),
                if (_checkInUrls[a.userId] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(_checkInUrls[a.userId]!, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
                  const SizedBox(width: 6),
                ],
                if (a.checkOutAt != null && a.checkOutAt!.isNotEmpty)
                  _pill('Đã check-out', const Color(0xFFDCFCE7), const Color(0xFF16A34A))
                else if (a.isCheckedIn)
                  _pill('Đã check-in', const Color(0xFFE0F2FE), const Color(0xFF0284C7))
                else
                  _pill('Chưa check-in', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _primary(String id, IconData icon, String label, VoidCallback onTap) {
    final busy = _busyId == id;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 16),
        label: Text(busy ? 'Đang xử lý…' : label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _secondary(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _info(IconData icon, String text, {Color? color, bool bold = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: color ?? AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: color ?? AppColors.textSecondary))),
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)));
  }

  Widget _tag(String label, ({Color bg, Color fg}) tone) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: tone.fg)));
  }

  String _changeType(String t) {
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
