import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/data/models/work_task_models.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FcmService _fcmService = FcmService();
  String? _confirmingPlanId;
  String _selectedFilter = 'ALL'; // 'ALL' | 'UNREAD' | 'READ'

  @override
  void initState() {
    super.initState();
    _fcmService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
      context.read<TaskProvider>().loadMyPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final notifProvider = context.watch<NotificationProvider>();
    final taskProvider = context.watch<TaskProvider>();

    final pendingConfirmPlans = taskProvider.myPlans
        .where((plan) {
          final assignee = user != null ? taskProvider.getMyAssignee(plan, user.id) : null;
          return plan.status == 'PENDING' && assignee?.role == 'LEAD';
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final planNotifications = taskProvider.myPlans.map((plan) {
      final notifId = 'plan_${plan.planId}';
      final defaultIsRead = plan.status == 'COMPLETED' || plan.status == 'CANCELLED';
      final isRead = notifProvider.isRead(notifId, defaultIsRead);
      return UserNotification(
        notificationId: notifId,
        userId: user?.id ?? '',
        title: 'Phân công công việc',
        content: 'Bạn được phân công phụ trách ${plan.taskName} (${plan.orderCode}${plan.eventName != null && plan.eventName!.isNotEmpty ? ' · ${plan.eventName}' : ''}).',
        type: 'ASSIGNMENT',
        isRead: isRead,
        createdAt: (plan.createdAt != null && plan.createdAt!.isNotEmpty)
            ? plan.createdAt!
            : DateTime.now().toIso8601String(),
      );
    }).toList();

    final apiNotifIds = notifProvider.notifications.map((n) => n.notificationId).toSet();
    final rawCombined = [
      ...notifProvider.notifications,
      ...planNotifications.where((p) => !apiNotifIds.contains(p.notificationId)),
    ];

    final combinedNotifications = rawCombined.map((n) {
      final isRead = notifProvider.isRead(n.notificationId, n.isRead);
      return UserNotification(
        notificationId: n.notificationId,
        userId: n.userId,
        title: n.title,
        content: n.content,
        type: n.type,
        isRead: isRead,
        createdAt: n.createdAt,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final unreadCount = combinedNotifications.where((n) => !n.isRead).length;
    final readCount = combinedNotifications.where((n) => n.isRead).length;

    List<UserNotification> filteredNotifications;
    if (_selectedFilter == 'UNREAD') {
      filteredNotifications = combinedNotifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'READ') {
      filteredNotifications = combinedNotifications.where((n) => n.isRead).toList();
    } else {
      filteredNotifications = combinedNotifications;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              notifProvider.loadNotifications(),
              taskProvider.loadMyPlans(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              AppHeader(
                title: 'Thông báo',
                subtitle: '$unreadCount chưa xem',
              ),
              const SizedBox(height: 12),

              // SECTION 1: USER NOTIFICATIONS LIST (DATABASE & LIVE PUSH & SYNTHESIZED ASSIGNMENTS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thông báo của tôi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(
                    'Tổng: ${combinedNotifications.length}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả (${combinedNotifications.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('UNREAD', 'Chưa đọc ($unreadCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('READ', 'Đã đọc ($readCount)'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (notifProvider.isLoading) ...[
                const AppLoadingIndicator(message: 'Đang nạp thông báo...'),
              ] else if (filteredNotifications.isEmpty) ...[
                EmptyStateWidget(
                  message: _selectedFilter == 'UNREAD'
                      ? 'Không có thông báo chưa đọc.'
                      : _selectedFilter == 'READ'
                          ? 'Không có thông báo nào đã đọc.'
                          : 'Bạn chưa có thông báo nào.',
                  icon: LucideIcons.bell,
                ),
              ] else ...[
                ...filteredNotifications.map(
                  (n) => InkWell(
                    onTap: () async {
                      await notifProvider.markAsRead(n.notificationId);
                      if (context.mounted) {
                        if (n.notificationId.startsWith('plan_')) {
                          final planId = n.notificationId.replaceFirst('plan_', '');
                          context.push('/staff/tasks/$planId');
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: n.isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: n.isRead ? AppColors.background : AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.bell,
                              size: 16,
                              color: n.isRead ? AppColors.textMuted : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (n.content != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    n.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(Formatters.formatDateTime(n.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // SECTION 2: PENDING PLANS CONFIRMATION SECTION (FOR LEAD)
              const Text('Kế hoạch cần xác nhận', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 10),

              if (pendingConfirmPlans.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Text('Không có kế hoạch nào đang chờ xác nhận.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ),
              ] else ...[
                ...pendingConfirmPlans.map(
                  (plan) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.taskName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('${plan.orderCode}${plan.eventName != null ? ' · ${plan.eventName}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(Formatters.formatDateTime(plan.startTime), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        AppButton(
                          text: 'Xác nhận kế hoạch',
                          isFullWidth: true,
                          isLoading: _confirmingPlanId == plan.planId,
                          onPressed: () async {
                            setState(() => _confirmingPlanId = plan.planId);
                            try {
                              await taskProvider.updatePlanStatus(plan.planId, 'CONFIRMED');
                              if (context.mounted) {
                                context.push('/staff/tasks/${plan.planId}');
                              }
                            } finally {
                              if (mounted) setState(() => _confirmingPlanId = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
