import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_role_badge.dart';
import '../../../authentication/data/models/auth_user.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/work_task_models.dart';
import '../../data/services/collected_report_api_service.dart';
import '../../data/services/deposit_api_service.dart';
import '../../data/services/evidence_api_service.dart';
import '../../data/services/inventory_api_service.dart';
import '../../data/services/settlement_api_service.dart';
import '../../data/services/supplier_transaction_api_service.dart';
import '../../data/services/survey_report_api_service.dart';
import '../providers/task_provider.dart';
import '../widgets/check_in_modal_bottom_sheet.dart';
import '../widgets/collected_report_section.dart';
import '../widgets/equipment_table.dart';
import '../widgets/field_payment_section.dart';
import '../widgets/handover_section.dart';
import '../widgets/settlement_section.dart';
import '../widgets/supplier_transaction_section.dart';
import '../widgets/survey_report_section.dart';
import '../widgets/warehouse_movement_section.dart';

class TaskDetailScreen extends StatefulWidget {
  final String planId;

  const TaskDetailScreen({
    super.key,
    required this.planId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _inventoryService = InventoryApiService();
  final _supplierService = SupplierTransactionApiService();
  final _surveyService = SurveyReportApiService();
  final _depositService = DepositApiService();
  final _collectedService = CollectedReportApiService();
  final _settlementService = SettlementApiService();
  final _evidenceService = EvidenceApiService();

  List<WorkTaskItem> _items = [];
  List<SupplierTransaction> _supplierTransactions = [];
  SurveyReport? _surveyReport;
  FieldPaymentRecord? _fieldPayment;
  CollectedEquipmentReport? _internalCollectedReport;
  CollectedEquipmentReport? _supplierCollectedReport;
  Settlement? _settlement;

  bool _isLoadingSubData = false;
  bool _isConfirming = false;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final taskProvider = context.read<TaskProvider>();
    final plan = taskProvider.getPlanById(widget.planId);
    if (plan == null) return;

    setState(() => _isLoadingSubData = true);

    try {
      // Picklist
      _items = await _inventoryService.getPicklist(plan.orderId);

      // Task specific data
      if (plan.taskCode == 'SETUP') {
        _supplierTransactions = await _supplierService.listWithItems(plan.orderId);
      }

      if (plan.taskCode == 'SURVEY') {
        final surveyRows = await _surveyService.listByPlanId(plan.planId);
        if (surveyRows.isNotEmpty) {
          final dto = surveyRows.first;
          String photoUrl = '';
          if (dto['evidenceId'] != null) {
            final ev = await _evidenceService.getById(dto['evidenceId'].toString());
            photoUrl = ev.fileUrl;
          }
          _surveyReport = SurveyReport.fromJson(dto, evidencePhotoUrl: photoUrl);
        }

        final deposits = await _depositService.list(plan.orderId);
        if (deposits.isNotEmpty) {
          final dto = deposits.first;
          String? photoUrl;
          if (dto['evidenceId'] != null) {
            final ev = await _evidenceService.getById(dto['evidenceId'].toString());
            photoUrl = ev.fileUrl;
          }
          _fieldPayment = FieldPaymentRecord.fromJson(dto, evidencePhotoUrl: photoUrl);
        }
      }

      if (plan.taskCode == 'COLLECT') {
        final reports = await _collectedService.listByOrderId(plan.orderId);
        _internalCollectedReport = reports.cast<CollectedEquipmentReport?>().firstWhere(
              (r) => r?.reportType == 'INTERNAL',
              orElse: () => null,
            );
        _supplierCollectedReport = reports.cast<CollectedEquipmentReport?>().firstWhere(
              (r) => r?.reportType == 'SUPPLIER',
              orElse: () => null,
            );

        _settlement = await _settlementService.getByOrderId(plan.orderId);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingSubData = false);
      }
    }
  }

  Future<void> _handleConfirmPlan() async {
    setState(() {
      _isConfirming = true;
      _confirmError = null;
    });

    try {
      await context.read<TaskProvider>().updatePlanStatus(widget.planId, 'CONFIRMED');
    } catch (e) {
      setState(() {
        _confirmError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<void> _handleUploadProgressPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;

    try {
      final ev = await _evidenceService.upload(File(image.path));
      if (mounted) {
        await context.read<TaskProvider>().patchEvidence(widget.planId, ev.evidenceId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final taskProvider = context.watch<TaskProvider>();
    final plan = taskProvider.getPlanById(widget.planId);

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết kế hoạch')),
        body: const Center(child: Text('Không tìm thấy kế hoạch này.')),
      );
    }

    final myAssignee = user != null ? taskProvider.getMyAssignee(plan, user.id) : null;
    final isLead = myAssignee?.role == 'LEAD';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(plan.taskName),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Thành viên'),
            Tab(text: 'Chấm công'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview
          _buildOverviewTab(plan, myAssignee, isLead, user, taskProvider),

          // Tab 2: Assignees
          _buildAssigneesTab(plan),

          // Tab 3: Attendance
          _buildAttendanceTab(plan, myAssignee, user),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(SchedulePlan plan, SchedulePlanAssignee? myAssignee, bool isLead, AuthUser? user, TaskProvider taskProvider) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Info Header Card
            Container(
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
                      AppBadge(
                        label: Formatters.formatStatus(plan.status),
                        backgroundColor: AppColors.primaryLight,
                        textColor: AppColors.primaryDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(plan.taskName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Đơn hàng: ${plan.orderCode}${plan.eventName != null ? ' · ${plan.eventName}' : ''}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildIconDetail(LucideIcons.user, 'Khách hàng', '${plan.customerName} (${plan.customerPhone})'),
                  const SizedBox(height: 6),
                  _buildIconDetail(LucideIcons.mapPin, 'Địa chỉ', plan.customerAddress),
                  const SizedBox(height: 6),
                  _buildIconDetail(LucideIcons.clock, 'Thời gian', '${Formatters.formatDateTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Plan action for LEAD role when PENDING
            if (isLead && plan.status == 'PENDING') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inProgressBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.inProgressText.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kế hoạch đang chờ xác nhận từ Trưởng nhóm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.inProgressText)),
                    const SizedBox(height: 8),
                    if (_confirmError != null) ...[
                      Text(_confirmError!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
                      const SizedBox(height: 8),
                    ],
                    AppButton(
                      text: 'Xác nhận kế hoạch công việc',
                      isFullWidth: true,
                      isLoading: _isConfirming,
                      onPressed: _handleConfirmPlan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Progress Evidence photo upload button for SETUP / COLLECT tasks
            if (plan.taskCode == 'SETUP' || plan.taskCode == 'COLLECT') ...[
              OutlinedButton.icon(
                onPressed: _handleUploadProgressPhoto,
                icon: const Icon(LucideIcons.camera, size: 18),
                label: const Text('Upload ảnh tiến độ thi công hiện trường'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              ),
              const SizedBox(height: 16),
            ],

            if (_isLoadingSubData) ...[
              const AppLoadingIndicator(message: 'Đang tải thông tin chi tiết hạng mục...'),
            ] else ...[
              // Task specific sections
              if (plan.taskCode == 'SURVEY') ...[
                SurveyReportSection(
                  existingReport: _surveyReport,
                  planStatus: plan.status,
                  onSubmit: (input) async {
                    final ev = await _evidenceService.upload(input.photoFile);
                    await _surveyService.create(
                      CreateSurveyReportBody(
                        orderId: plan.orderId,
                        planId: plan.planId,
                        surveyDate: plan.startTime,
                        location: plan.location ?? plan.customerAddress,
                        area: input.area,
                        length: input.length,
                        width: input.width,
                        entrance: input.entrance,
                        siteConstraints: input.siteConstraints,
                        proposedItems: input.proposedItems,
                        notes: input.notes,
                        evidenceId: ev.evidenceId,
                      ),
                    );
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                FieldPaymentSection(
                  existingPayment: _fieldPayment,
                  onSubmit: (input) async {
                    String? evId;
                    if (input.photoFile != null) {
                      final ev = await _evidenceService.upload(input.photoFile!);
                      evId = ev.evidenceId;
                    }
                    await _depositService.create(
                      plan.orderId,
                      CreateDepositBody(
                        amount: input.amount,
                        paymentMethod: input.method,
                        evidenceId: evId,
                        notes: input.note,
                      ),
                    );
                    await _loadData();
                  },
                ),
              ],

              if (plan.taskCode == 'SETUP') ...[
                EquipmentTable(items: _items),
                const SizedBox(height: 16),
                SupplierTransactionSection(
                  transactions: _supplierTransactions,
                  onReceiveItem: (txId, stItemId, qty) async {
                    await _supplierService.receiveItem(txId, stItemId, qty);
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                WarehouseMovementSection(
                  items: _items,
                  onSubmit: (input) async {
                    await taskProvider.warehouseMovement(plan.planId, input.items, notes: input.notes);
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                HandoverSection(
                  onSubmit: (note, photoFile) async {
                    final ev = await _evidenceService.upload(photoFile);
                    await taskProvider.patchEvidence(plan.planId, ev.evidenceId);
                    await _loadData();
                  },
                ),
              ],

              if (plan.taskCode == 'COLLECT') ...[
                EquipmentTable(items: _items),
                const SizedBox(height: 16),
                CollectedEquipmentReportSection(
                  existingInternalReport: _internalCollectedReport,
                  existingSupplierReport: _supplierCollectedReport,
                  items: _items,
                  onSubmit: (input) async {
                    await _collectedService.create(
                      plan.orderId,
                      CreateCollectedReportBody(
                        reportType: input.reportType,
                        transactionId: input.transactionId,
                        notes: input.notes,
                        items: input.items,
                      ),
                    );
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                SettlementSection(
                  existingSettlement: _settlement,
                  onMarkPaid: (photoFile) async {
                    if (_settlement != null) {
                      final ev = await _evidenceService.upload(photoFile);
                      await _settlementService.markPaid(_settlement!.settlementId, ev.evidenceId);
                      await _loadData();
                    }
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneesTab(SchedulePlan plan) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Danh sách phân công (${plan.assignees.length} nhân sự)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...plan.assignees.map(
          (assignee) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(Formatters.getInitial(assignee.fullName), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(assignee.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          AppRoleBadge(roleName: assignee.role),
                        ],
                      ),
                      if (assignee.phone != null) Text(assignee.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        assignee.isCheckedIn
                            ? 'Check-in: ${Formatters.formatDateTime(assignee.checkInAt)}'
                            : 'Chưa check-in',
                        style: TextStyle(
                          fontSize: 11,
                          color: assignee.isCheckedIn ? AppColors.completedText : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(SchedulePlan plan, SchedulePlanAssignee? myAssignee, AuthUser? user) {
    final isCheckedIn = myAssignee?.isCheckedIn ?? false;
    final isCheckedOut = myAssignee?.isCheckedOut ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trạng thái điểm danh cá nhân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildAttendanceRow('Check-in:', isCheckedIn ? Formatters.formatDateTime(myAssignee!.checkInAt) : 'Chưa điểm danh', isCheckedIn),
                const SizedBox(height: 8),
                _buildAttendanceRow('Check-out:', isCheckedOut ? Formatters.formatDateTime(myAssignee!.checkOutAt) : 'Chưa check-out', isCheckedOut),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!isCheckedIn && user != null) ...[
            AppButton(
              text: 'Điểm danh Check-in hiện trường',
              isFullWidth: true,
              onPressed: () {
                CheckInModalBottomSheet.show(
                  context,
                  taskName: plan.taskName,
                  locationName: plan.location,
                  onConfirmCheckIn: (photoFile) async {
                    await context.read<TaskProvider>().checkIn(plan.planId, user.id);
                  },
                );
              },
            ),
          ] else if (isCheckedIn && !isCheckedOut && user != null) ...[
            AppButton(
              text: 'Xác nhận Check-out rời vị trí',
              isFullWidth: true,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                context.read<TaskProvider>().checkOut(plan.planId, user.id);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(String label, String val, bool isDone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDone ? AppColors.completedText : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildIconDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
