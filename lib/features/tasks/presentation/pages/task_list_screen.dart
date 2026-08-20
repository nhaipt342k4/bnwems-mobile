import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/services/evidence_api_service.dart';
import '../providers/task_provider.dart';
import '../widgets/check_in_modal_bottom_sheet.dart';
import '../widgets/current_task_card.dart';
import '../widgets/upcoming_event_alert.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, String>> _statusFilters = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING', 'label': 'Chờ xác nhận'},
    {'key': 'CONFIRMED', 'label': 'Đã xác nhận'},
    {'key': 'IN_PROGRESS', 'label': 'Đang thực hiện'},
    {'key': 'COMPLETED', 'label': 'Hoàn thành'},
    {'key': 'CANCELLED', 'label': 'Đã hủy'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final taskProvider = context.watch<TaskProvider>();
    final filteredPlans = taskProvider.getFilteredPlans();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final upcomingPlans = taskProvider.myPlans
        .where((plan) => plan.startTime.startsWith(todayStr) && plan.status != 'CANCELLED' && plan.status != 'COMPLETED')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.goldPrimary,
          onRefresh: () => taskProvider.loadMyPlans(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18.0),
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CÔNG VIỆC',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLabel,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Danh sách nhiệm vụ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.warmTextDark,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search bar (Pill shape)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) => taskProvider.setSearchQuery(query),
                  style: const TextStyle(fontSize: 14, color: AppColors.warmTextDark),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên việc, mã đơn, sự kiện...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.goldPrimary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16, color: AppColors.warmTextMuted),
                            onPressed: () {
                              _searchController.clear();
                              taskProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Horizontal Status Filters
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _statusFilters[index];
                    final isSelected = taskProvider.selectedStatusFilter == filter['key'];
                    return GestureDetector(
                      onTap: () => taskProvider.setStatusFilter(filter['key']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldPrimary : const Color(0xFFF7F2EA),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          filter['label']!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.goldLabel,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Upcoming Event Alert
              UpcomingEventAlert(plans: upcomingPlans),
              if (upcomingPlans.isNotEmpty) const SizedBox(height: 16),

              // Plans list
              if (taskProvider.isLoading) ...[
                const AppLoadingIndicator(message: 'Đang tải danh sách công việc...'),
              ] else if (filteredPlans.isEmpty) ...[
                const EmptyStateWidget(
                  message: 'Không có kế hoạch nào phù hợp với bộ lọc.',
                  icon: LucideIcons.calendarX,
                ),
              ] else ...[
                ...filteredPlans.map(
                  (plan) {
                    final activePlan = user != null ? taskProvider.getActiveCheckedInPlan(user.id) : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CurrentTaskCard(
                        plan: plan,
                        myAssignee: user != null ? taskProvider.getMyAssignee(plan, user.id) : null,
                        activePlan: activePlan,
                        onCheckInPressed: () {
                          if (user != null) {
                            final activePlan = taskProvider.getActiveCheckedInPlan(user.id);
                            if (activePlan != null && activePlan.planId != plan.planId) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bạn đang thực hiện công việc "${activePlan.taskName}" (${activePlan.planCode}) chưa check-out. Vui lòng check-out trước khi check-in công việc mới.'),
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
                                  final ev = await EvidenceApiService().upload(photoFile);
                                  evidenceId = ev.evidenceId;
                                } catch (_) {}
                                await taskProvider.checkIn(
                                  plan.planId,
                                  user.id,
                                  checkInEvidenceId: evidenceId,
                                  latitude: lat,
                                  longitude: lng,
                                );
                              },
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
