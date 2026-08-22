import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../authentication/data/models/auth_user.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/quotation_item_model.dart';
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
import '../widgets/technical_task_view.dart';

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

  final _apiClient = ApiClient();
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
  List<CollectedEquipmentReport> _supplierCollectedReports = [];
  Settlement? _settlement;
  List<String> _handoverEvidenceUrls = [];
  num _depositCollected = 0;
  double _suggestedCompensation = 0.0;
  bool _isWarehouseConfirmed = false;
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

    int pendingTasks = 0;
    void checkFinished() {
      pendingTasks--;
      if (pendingTasks <= 0 && mounted) {
        setState(() => _isLoadingSubData = false);
      }
    }

    // 1. Picklist (Equipment items)
    if (plan.taskCode == 'SETUP' || plan.taskCode == 'COLLECT') {
      pendingTasks++;
      _inventoryService.getPicklist(plan.orderId).then((items) {
        if (mounted) setState(() => _items = items);
      }).catchError((_) {}).whenComplete(checkFinished);
    }

    // 2. Supplier Transactions
    if (plan.taskCode == 'SETUP' || plan.taskCode == 'COLLECT') {
      pendingTasks++;
      _supplierService.listWithItems(plan.orderId).then((txs) {
        if (mounted) setState(() => _supplierTransactions = txs);
      }).catchError((_) {}).whenComplete(checkFinished);
    }

    // 2.5 Setup Handover Evidence
    if (plan.taskCode == 'SETUP' && plan.evidenceIds.isNotEmpty) {
      pendingTasks++;
      Future(() async {
        final urls = <String>[];
        for (final id in plan.evidenceIds) {
          try {
            urls.add((await _evidenceService.getById(id)).fileUrl);
          } catch (_) {}
        }
        if (mounted) setState(() => _handoverEvidenceUrls = urls);
      }).whenComplete(checkFinished);
    }

    // 3. Survey Report
    if (plan.taskCode == 'SURVEY') {
      pendingTasks++;
      _surveyService.listByPlanId(plan.planId).then((surveyRows) async {
        if (surveyRows.isNotEmpty) {
          final surveyId = surveyRows.first['surveyId']?.toString();
          if (surveyId != null) {
            try {
              final detail = await _surveyService.getById(surveyId);
              final urls = <String>[];
              for (final id in parseEvidenceIds(detail['evidenceIds'])) {
                try {
                  urls.add((await _evidenceService.getById(id)).fileUrl);
                } catch (_) {}
              }

              List<QuotationItemInput> quotationItemsFromOrder = [];
              try {
                final orderRes = await _apiClient.fetchData<Map<String, dynamic>>('/orders/${plan.orderId}');
                final quotationId = orderRes['quotationId']?.toString();
                if (quotationId != null && quotationId.isNotEmpty) {
                  final quotationRes = await _apiClient.fetchData<Map<String, dynamic>>('/quotations/$quotationId');
                  if (quotationRes['items'] is List) {
                    quotationItemsFromOrder = (quotationRes['items'] as List).map((i) {
                      final map = i as Map<String, dynamic>;
                      return QuotationItemInput(
                        id: map['quotationItemId']?.toString() ?? map['id']?.toString() ?? '',
                        itemId: map['itemId']?.toString(),
                        name: map['itemName']?.toString() ?? map['name']?.toString() ?? 'Thiết bị',
                        category: map['categoryName']?.toString() ?? map['category']?.toString() ?? 'Hạng mục',
                        unit: map['unit']?.toString() ?? 'cái',
                        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
                        unitPrice: (map['unitPrice'] ?? map['price'] as num?)?.toDouble() ?? 0.0,
                        discountPerItem: (map['discount'] as num?)?.toDouble() ?? 0.0,
                      );
                    }).toList();
                  }
                }
              } catch (_) {}

              if (mounted) {
                setState(() => _surveyReport = SurveyReport.fromJson(
                  detail,
                  evidencePhotoUrls: urls,
                  extraQuotationItems: quotationItemsFromOrder,
                ));
              }
            } catch (_) {}
          }
        }
      }).catchError((_) {}).whenComplete(checkFinished);

      pendingTasks++;
      _depositService.list(plan.orderId).then((deposits) async {
        if (deposits.isNotEmpty) {
          final d = deposits.first;
          String? photoUrl;
          final ids = parseEvidenceIds(d['evidenceIds']);
          if (ids.isNotEmpty) {
            try {
              photoUrl = (await _evidenceService.getById(ids.first)).fileUrl;
            } catch (_) {}
          }
          if (mounted) {
            setState(() => _fieldPayment = FieldPaymentRecord.fromJson(d, evidencePhotoUrl: photoUrl));
          }
        }
      }).catchError((_) {}).whenComplete(checkFinished);
    }

    // 4. Collected Reports
    if (plan.taskCode == 'COLLECT') {
      pendingTasks++;
      _collectedService.listByOrderId(plan.orderId).then((reports) {
        if (mounted) {
          setState(() {
            _internalCollectedReport = reports.cast<CollectedEquipmentReport?>().firstWhere(
                  (r) => r?.reportType == 'INTERNAL',
                  orElse: () => null,
                );
            _supplierCollectedReports = reports.where((r) => r.reportType == 'SUPPLIER').toList();
          });
        }
      }).catchError((_) {}).whenComplete(checkFinished);

      pendingTasks++;
      _settlementService.getByOrderId(plan.orderId).then((settlement) {
        if (mounted) setState(() => _settlement = settlement);
      }).catchError((_) {}).whenComplete(checkFinished);

      pendingTasks++;
      _depositService.list(plan.orderId).then((deposits) {
        if (mounted) {
          final sum = deposits
              .where((d) => d['status'] == 'PAID')
              .fold(0.0, (acc, d) => acc + (num.tryParse(d['amount']?.toString() ?? '0') ?? 0));
          setState(() => _depositCollected = sum);
        }
      }).catchError((_) {}).whenComplete(checkFinished);
    }

    if (pendingTasks == 0 && mounted) {
      setState(() => _isLoadingSubData = false);
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
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          plan.taskName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.warmTextDark,
            fontFamily: 'serif',
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 18, color: Color(0xFF8C7355)),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.goldPrimary,
          unselectedLabelColor: const Color(0xFF8C7355),
          indicatorColor: AppColors.goldPrimary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
          _buildAttendanceTab(plan, myAssignee, user, context),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(SchedulePlan plan, SchedulePlanAssignee? myAssignee, bool isLead, AuthUser? user, TaskProvider taskProvider) {
    if (!isLead) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: TechnicalTaskView(
          plan: plan,
          myAssignee: myAssignee,
          user: user,
          taskProvider: taskProvider,
          items: _items,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Task Header Card (Vibrant Warm Gold Gradient)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC59B63), Color(0xFFA87E46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
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
                        plan.planCode,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF7EEDD)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9EE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          Formatters.formatStatus(plan.status),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8C7355),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.taskName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đơn hàng: ${Formatters.formatOrderEvent(plan.orderCode, plan.eventName)}',
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFFFDE68A), fontWeight: FontWeight.bold),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFD9B687)),
                  ),
                  _buildIconDetail(LucideIcons.user, 'Khách hàng', '${plan.customerName} (${plan.customerPhone})', isDarkCard: true),
                  const SizedBox(height: 12),
                  _buildIconDetail(
                    LucideIcons.mapPin,
                    'Địa chỉ hiện trường',
                    plan.location != null && plan.location!.trim().isNotEmpty
                        ? plan.location!
                        : (plan.customerAddress.isNotEmpty ? plan.customerAddress : 'Chưa có địa chỉ'),
                    isDarkCard: true,
                  ),
                  const SizedBox(height: 12),
                  _buildIconDetail(
                    LucideIcons.clock,
                    'Thời gian',
                    '${Formatters.formatDateTime(plan.startTime)}${plan.endTime != null ? ' - ${Formatters.formatTime(plan.endTime)}' : ''}',
                    isDarkCard: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Plan action for LEAD role when PENDING
            if (isLead && plan.status == 'PENDING') ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, size: 18, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kế hoạch đang chờ xác nhận từ Trưởng nhóm',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

            if (_isLoadingSubData) ...[
              const AppLoadingIndicator(message: 'Đang tải thông tin chi tiết hạng mục...'),
            ] else ...[
              // Task specific sections
              if (plan.taskCode == 'SURVEY') ...[
                SurveyReportSection(
                  planId: plan.planId,
                  existingReport: _surveyReport,
                  planStatus: plan.status,
                  isSubmitted: taskProvider.isSurveySubmitted(plan.planId),
                  onSubmit: (input) async {
                    final evidenceIds = <String>[];
                    final photo = input.primaryPhoto;
                    if (photo != null) {
                      try {
                        final primaryEv = await _evidenceService.upload(photo);
                        evidenceIds.add(primaryEv.evidenceId);
                      } catch (e) {
                        debugPrint('Primary photo upload error: $e');
                      }
                    }
                    for (final photo in input.photoFiles) {
                      try {
                        final ev = await _evidenceService.upload(photo);
                        evidenceIds.add(ev.evidenceId);
                      } catch (_) {}
                    }

                    try {
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
                          evidenceIds: evidenceIds,
                          quotationItems: input.quotationItems.map((item) => item.toJson()).toList(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Survey report create error: $e');
                    }

                    if (input.quotationItems.isNotEmpty) {
                      try {
                        final orderRes = await _apiClient.fetchData<Map<String, dynamic>>('/orders/${plan.orderId}');
                        final customerId = orderRes['customerId']?.toString() ?? orderRes['customer']?['customerId']?.toString() ?? plan.orderId;
                        final existingQuotationId = orderRes['quotationId']?.toString();

                        List<String> validCatalogIds = [];
                        try {
                          final catalogRes = await _apiClient.fetchData<List<dynamic>>('/catalog/items');
                          validCatalogIds = catalogRes
                              .map((row) => (row as Map<String, dynamic>)['itemId']?.toString())
                              .where((id) => id != null && id.isNotEmpty)
                              .cast<String>()
                              .toList();
                        } catch (_) {
                          try {
                            final invRes = await _apiClient.fetchData<List<dynamic>>('/inventory');
                            validCatalogIds = invRes
                                .map((row) => (row as Map<String, dynamic>)['itemId']?.toString())
                                .where((id) => id != null && id.isNotEmpty)
                                .cast<String>()
                                .toList();
                          } catch (_) {}
                        }

                        final fallbackItemId = validCatalogIds.isNotEmpty ? validCatalogIds.first : 'ITM-001';

                        final quotationBodyItems = input.quotationItems.map((item) {
                          final rawId = (item.itemId != null && item.itemId!.isNotEmpty) ? item.itemId! : item.id;
                          final effectiveItemId = (validCatalogIds.isEmpty || validCatalogIds.contains(rawId))
                              ? rawId
                              : fallbackItemId;

                          return {
                            'itemId': effectiveItemId,
                            'quantity': item.quantity,
                            'price': item.unitPrice,
                            'discount': item.discountPerItem,
                          };
                        }).toList();

                        if (existingQuotationId != null && existingQuotationId.isNotEmpty) {
                          await _apiClient.fetchData<Map<String, dynamic>>(
                            '/quotations/$existingQuotationId',
                            method: 'PUT',
                            body: {
                              'version': 'v1',
                              'notes': 'Cập nhật báo giá khảo sát hiện trường (${plan.planCode})',
                              'items': quotationBodyItems,
                            },
                          );
                        } else {
                          final newQuo = await _surveyService.createCustomerQuotation(
                            customerId: customerId,
                            items: quotationBodyItems,
                            notes: 'Báo giá khảo sát hiện trường (${plan.planCode})',
                          );
                          final newQuotationId = newQuo['quotationId']?.toString() ?? newQuo['id']?.toString();
                          if (newQuotationId != null && newQuotationId.isNotEmpty) {
                            try {
                              await _apiClient.fetchData<Map<String, dynamic>>(
                                '/orders/${plan.orderId}/quotation',
                                method: 'PATCH',
                                body: {'quotationId': newQuotationId},
                              );
                            } catch (err) {
                              debugPrint('Order quotation link error: $err');
                            }
                          }
                        }
                      } catch (err) {
                        debugPrint('Quotation sync error: $err');
                      }
                    }

                    taskProvider.markSurveySubmitted(plan.planId);
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
                        notes: (input.note != null && input.note!.isNotEmpty) ? input.note : null,
                      ),
                    );
                    await _loadData();
                  },
                ),
              ],

              if (plan.taskCode == 'SETUP') ...[
                EquipmentTable(
                  items: _items,
                  isWarehouseConfirmed: _isWarehouseConfirmed || taskProvider.isWarehouseConfirmed(plan.planId) || plan.status == 'COMPLETED',
                  onConfirmWarehouseMovement: (notes) async {
                    final movementItems = _items
                        .where((i) => (i.source == null || i.source == 'INTERNAL') && i.internalNeed > 0)
                        .map((i) => {'itemId': i.itemId, 'quantity': i.internalNeed})
                        .toList();
                    await taskProvider.warehouseMovement(plan.planId, movementItems, notes: notes);
                    if (mounted) {
                      setState(() {
                        _isWarehouseConfirmed = true;
                      });
                    }
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                SupplierTransactionSection(
                  transactions: _supplierTransactions,
                  onReceiveItem: (txId, stItemId, qty) async {
                    await _supplierService.receiveItem(txId, stItemId, qty);
                    await _loadData();
                  },
                  onConfirmReceived: (txId) async {
                    await _supplierService.confirmReceived(txId);
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                HandoverSection(
                  existingNotes: plan.notes,
                  existingPhotoUrls: _handoverEvidenceUrls,
                  isAlreadySubmitted: taskProvider.isHandoverSubmitted(plan.planId),
                  onSubmit: (note, photoFiles) async {
                    final evidenceIds = <String>[];
                    for (final photo in photoFiles) {
                      final ev = await _evidenceService.upload(
                        photo,
                        description: note.isNotEmpty ? note : null,
                      );
                      evidenceIds.add(ev.evidenceId);
                    }
                    if (evidenceIds.isNotEmpty) {
                      await taskProvider.patchEvidence(plan.planId, evidenceIds);
                    }
                    taskProvider.markHandoverSubmitted(plan.planId);
                    await _loadData();
                  },
                ),
              ],

              if (plan.taskCode == 'COLLECT') ...[
                EquipmentTable(items: _items),
                const SizedBox(height: 16),
                CollectedEquipmentReportSection(
                  existingInternalReport: _internalCollectedReport,
                  existingSupplierReports: _supplierCollectedReports,
                  items: _items,
                  supplierTransactions: _supplierTransactions,
                  isWarehouseConfirmed: _internalCollectedReport?.status == 'CONFIRMED',
                  onCompensationChanged: (suggested) {
                    if (mounted && _suggestedCompensation != suggested) {
                      setState(() => _suggestedCompensation = suggested);
                    }
                  },
                  onSubmit: (input) async {
                    final evidenceIds = <String>[];
                    for (final photo in input.photoFiles) {
                      try {
                        final ev = await _evidenceService.upload(photo);
                        evidenceIds.add(ev.evidenceId);
                      } catch (_) {}
                    }
                    await _collectedService.create(
                      plan.orderId,
                      CreateCollectedReportBody(
                        reportType: input.reportType,
                        transactionId: input.transactionId,
                        notes: input.notes,
                        items: input.items,
                        evidenceIds: evidenceIds,
                      ),
                    );
                    await _loadData();
                  },
                  onConfirmWarehouse: () async {
                    final report = _internalCollectedReport;
                    if (report == null) return;
                    await _collectedService.confirm(report.reportId);
                    await _loadData();
                  },
                ),
                const SizedBox(height: 16),
                SettlementSection(
                  existingSettlement: _settlement,
                  orderCode: plan.orderCode,
                  eventName: plan.eventName,
                  customerName: plan.customerName,
                  eventDate: plan.startTime,
                  depositCollected: _depositCollected,
                  suggestedCompensation: _suggestedCompensation,
                  onSubmitSettlement: (input) async {
                    String? evId;
                    if (input.photoFile != null) {
                      final ev = await _evidenceService.upload(input.photoFile!);
                      evId = ev.evidenceId;
                    }
                    final settlementId = await _settlementService.create(
                      plan.orderId,
                      CreateSettlementBody(
                        additionalFee: input.additionalFee,
                        compensation: input.compensation,
                        discount: input.discount,
                        paymentMethod: input.paymentMethod,
                        notes: input.notes,
                      ),
                    );
                    if (evId != null && settlementId.isNotEmpty) {
                      try {
                        await _settlementService.markPaid(settlementId, evId);
                      } catch (_) {}
                    }
                    await _loadData();
                  },
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
      padding: const EdgeInsets.all(18),
      children: [
        Text.rich(
          TextSpan(
            text: 'Danh sách phân công ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.warmTextDark,
            ),
            children: [
              TextSpan(
                text: '(${plan.assignees.length} nhân sự)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.warmTextMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...plan.assignees.map((assignee) {
          final isLead = assignee.role == 'LEAD';
          final roleLabel = Formatters.formatRole(assignee.role);

          String checkInStr = 'Chưa check-in';
          if (assignee.isCheckedIn && assignee.checkInAt != null && assignee.checkInAt!.isNotEmpty) {
            try {
              final dt = Formatters.parseVietnamDateTime(assignee.checkInAt!);
              final hh = dt.hour.toString().padLeft(2, '0');
              final mm = dt.minute.toString().padLeft(2, '0');
              final dd = dt.day.toString().padLeft(2, '0');
              final mon = dt.month.toString().padLeft(2, '0');
              final yyyy = dt.year.toString();
              checkInStr = 'Check-in: $hh:$mm - $dd/$mon/$yyyy';
            } catch (_) {
              checkInStr = 'Check-in: ${assignee.checkInAt}';
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
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
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLead ? const Color(0xFFF3E8FF) : const Color(0xFFF5EAD8),
                  ),
                  child: Center(
                    child: Text(
                      Formatters.getInitial(assignee.fullName),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLead ? const Color(0xFF7E22CE) : const Color(0xFF8C7355),
                        fontSize: 18,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            assignee.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmTextDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLead ? const Color(0xFFF3E8FF) : const Color(0xFFF7F2EA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLead ? const Color(0xFFE9D5FF) : const Color(0xFFEFE8DC),
                              ),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLead ? const Color(0xFF7E22CE) : const Color(0xFF8C7456),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (assignee.phone != null && assignee.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          assignee.phone!,
                          style: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        checkInStr,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: assignee.isCheckedIn ? const Color(0xFF16A34A) : AppColors.warmTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttendanceTab(SchedulePlan plan, SchedulePlanAssignee? myAssignee, AuthUser? user, BuildContext context) {
    final isCheckedIn = myAssignee?.isCheckedIn ?? false;
    final isCheckedOut = myAssignee?.isCheckedOut ?? false;
    final activePlan = user != null ? context.watch<TaskProvider>().getActiveCheckedInPlan(user.id) : null;
    final hasOtherActivePlan = activePlan != null && activePlan.planId != plan.planId;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
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
                const Text(
                  'Trạng thái điểm danh cá nhân',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmTextDark,
                  ),
                ),
                const SizedBox(height: 14),
                _buildAttendanceRow('Check-in:', isCheckedIn ? Formatters.formatDateTime(myAssignee!.checkInAt) : 'Chưa điểm danh', isCheckedIn),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFF0E8DC)),
                ),
                _buildAttendanceRow('Check-out:', isCheckedOut ? Formatters.formatDateTime(myAssignee!.checkOutAt) : 'Chưa check-out', isCheckedOut),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!isCheckedIn && user != null) ...[
            if (hasOtherActivePlan) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn không được check-in khi chưa hoàn thành (check-out) công việc "${activePlan.taskName}" (${activePlan.planCode}).',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (hasOtherActivePlan) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bạn không được check-in khi chưa hoàn thành công việc "${activePlan.taskName}" (${activePlan.planCode}).'),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    return;
                  }
                  CheckInModalBottomSheet.show(
                    context,
                    taskName: plan.taskName,
                    locationName: plan.location,
                    targetLatitude: plan.latitude,
                    targetLongitude: plan.longitude,
                    onConfirmCheckIn: (photoFile, lat, lng) async {
                      String? evidenceId;
                      try {
                        final ev = await _evidenceService.upload(photoFile);
                        evidenceId = ev.evidenceId;
                      } catch (_) {}
                      if (context.mounted) {
                        await context.read<TaskProvider>().checkIn(
                          plan.planId,
                          user.id,
                          checkInEvidenceId: evidenceId,
                          latitude: lat,
                          longitude: lng,
                        );
                      }
                    },
                  );
                },
                icon: Icon(hasOtherActivePlan ? LucideIcons.lock : LucideIcons.checkCircle2, size: 18),
                label: Text(
                  hasOtherActivePlan ? 'Nút Check-in đã bị khóa' : 'Điểm danh Check-in hiện trường',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasOtherActivePlan ? Colors.grey.shade300 : AppColors.goldPrimary,
                  foregroundColor: hasOtherActivePlan ? Colors.grey.shade700 : Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ] else if (isCheckedIn && !isCheckedOut && user != null) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await context.read<TaskProvider>().checkOut(plan.planId, user.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Check-out thành công!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final cleanMsg = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(LucideIcons.alertTriangle, color: AppColors.cancelledText, size: 22),
                              SizedBox(width: 8),
                              Text('Chưa thể Check-out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Text(cleanMsg, style: const TextStyle(fontSize: 14)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Đã hiểu'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text(
                  'Xác nhận Check-out rời vị trí',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C241E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2C241E).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
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
        Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.warmTextMuted)),
        Text(
          val,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDone ? const Color(0xFF16A34A) : AppColors.warmTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildIconDetail(IconData icon, String label, String value, {bool isDarkCard = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkCard ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF7F2EA),
          ),
          child: Icon(icon, size: 15, color: isDarkCard ? Colors.white : AppColors.goldPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDarkCard ? const Color(0xFFE8DCCB) : AppColors.warmTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDarkCard ? Colors.white : AppColors.warmTextDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
