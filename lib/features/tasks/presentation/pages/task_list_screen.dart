import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => taskProvider.loadMyPlans(currentUserId: user?.id),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              const AppHeader(
                title: 'Công việc',
                subtitle: 'Danh sách nhiệm vụ được giao',
              ),
              const SizedBox(height: 8),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (query) => taskProvider.setSearchQuery(query),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên việc, mã đơn, sự kiện...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            taskProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),

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
                    return ChoiceChip(
                      label: Text(
                        filter['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      onSelected: (_) => taskProvider.setStatusFilter(filter['key']!),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Upcoming Event Alert
              UpcomingEventAlert(plans: upcomingPlans),
              if (upcomingPlans.isNotEmpty) const SizedBox(height: 16),

              // Plans list
              if (taskProvider.isLoading) ...[
                const AppLoadingIndicator(message: 'Đang nạp danh sách công việc...'),
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
                      padding: const EdgeInsets.only(bottom: 12),
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
                              onConfirmCheckIn: (photoFile) async {
                                await taskProvider.checkIn(plan.planId, user.id);
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
