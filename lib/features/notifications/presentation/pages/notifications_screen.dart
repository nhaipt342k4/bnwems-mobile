import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
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
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              notifProvider.loadNotifications(),
              taskProvider.loadMyPlans(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(18.0),
            children: [
              // Header Main Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (context.canPop()) ...[
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
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
                        child: const Icon(LucideIcons.arrowLeft, color: AppColors.warmTextDark, size: 20),
                      ),
                    ),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'THÔNG BÁO',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLabel,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thông báo của tôi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.warmTextDark,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

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
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bell circle badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: n.isRead ? const Color(0xFFFAF6F0) : const Color(0xFFF7F2EA),
                            ),
                            child: Icon(
                              LucideIcons.bell,
                              size: 20,
                              color: n.isRead ? const Color(0xFFA89A8B) : AppColors.goldPrimary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: AppColors.warmTextDark,
                                  ),
                                ),
                                if (n.content != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    n.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF5C4E43),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  Formatters.formatDateTime(n.createdAt),
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.warmTextMuted),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6, left: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.goldPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // SECTION 2: PENDING PLANS CONFIRMATION SECTION (FOR LEAD)
              const Text(
                'Kế hoạch cần xác nhận',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warmTextDark,
                ),
              ),
              const SizedBox(height: 12),

              if (pendingConfirmPlans.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Không có kế hoạch nào đang chờ xác nhận.',
                    style: TextStyle(fontSize: 13.5, color: AppColors.warmTextMuted),
                  ),
                ),
              ] else ...[
                ...pendingConfirmPlans.map(
                  (plan) => Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.taskName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'serif',
                            color: AppColors.warmTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.orderCode}${plan.eventName != null ? ' · ${plan.eventName}' : ''}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.formatDateTime(plan.startTime),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5C4E43)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldPrimary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
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
                            child: _confirmingPlanId == plan.planId
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Xác nhận kế hoạch',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary : const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFEFE8DC)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.goldPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF8C7456),
          ),
        ),
      ),
    );
  }
}
