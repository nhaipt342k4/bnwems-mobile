import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../tasks/data/models/work_task_models.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  State<ManagerNotificationsScreen> createState() => _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState extends State<ManagerNotificationsScreen> {
  final FcmService _fcmService = FcmService();
  String _filter = 'ALL'; // 'ALL' | 'UNREAD'

  @override
  void initState() {
    super.initState();
    _fcmService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  void _navigateToTarget(UserNotification n) {
    final titleLower = n.title.toLowerCase();
    final contentLower = (n.content ?? '').toLowerCase();

    final RegExp orderRegExp = RegExp(r'ORD-\d+', caseSensitive: false);
    final match = orderRegExp.firstMatch(n.title) ?? orderRegExp.firstMatch(n.content ?? '');
    final orderCode = match?.group(0)?.toUpperCase();

    if (titleLower.contains('quyết toán') || contentLower.contains('quyết toán') || titleLower.contains('settlement')) {
      if (orderCode != null) {
        context.push('/manager/settlements/$orderCode');
      } else {
        context.push('/manager/pending');
      }
    } else if (titleLower.contains('đặt cọc') || contentLower.contains('đặt cọc') || titleLower.contains('deposit')) {
      if (orderCode != null) {
        context.push('/manager/deposits/$orderCode');
      } else {
        context.push('/manager/pending');
      }
    } else if (titleLower.contains('thay đổi thiết bị') || contentLower.contains('thay đổi thiết bị') || titleLower.contains('change request')) {
      context.push('/manager/change-requests');
    } else if (titleLower.contains('thu hồi') || contentLower.contains('thu hồi') || titleLower.contains('hoàn trả')) {
      context.push('/manager/returns');
    } else if (orderCode != null) {
      context.push('/manager/orders/$orderCode');
    } else {
      context.push('/manager/pending');
    }
  }

  IconData _getNotificationIcon(UserNotification n) {
    final titleLower = n.title.toLowerCase();
    final contentLower = (n.content ?? '').toLowerCase();

    if (titleLower.contains('quyết toán') || contentLower.contains('quyết toán')) {
      return LucideIcons.receipt;
    }
    if (titleLower.contains('đặt cọc') || contentLower.contains('đặt cọc')) {
      return LucideIcons.wallet;
    }
    if (titleLower.contains('thay đổi thiết bị') || contentLower.contains('thay đổi thiết bị')) {
      return LucideIcons.fileSpreadsheet;
    }
    if (titleLower.contains('thu hồi') || contentLower.contains('hoàn trả')) {
      return LucideIcons.packageCheck;
    }
    return LucideIcons.bell;
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    final filteredList = _filter == 'UNREAD'
        ? notifications.where((n) => !notifProvider.isRead(n.notificationId, n.isRead)).toList()
        : notifications;

    final unreadCount = notifProvider.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.goldPrimary,
          onRefresh: () async {
            await notifProvider.loadNotifications();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
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
                              'Thông báo quản lý',
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
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          for (final n in notifications) {
                            if (!notifProvider.isRead(n.notificationId, n.isRead)) {
                              notifProvider.markAsRead(n.notificationId);
                            }
                          }
                        },
                        child: const Text(
                          'Đọc tất cả',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                        ),
                      ),
                  ],
                ),
              ),

              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả (${notifications.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('UNREAD', 'Chưa đọc ($unreadCount)'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Notifications List
              Expanded(
                child: notifProvider.isLoading
                    ? const AppLoadingIndicator(message: 'Đang nạp thông báo...')
                    : filteredList.isEmpty
                        ? const EmptyStateWidget(
                            message: 'Không có thông báo nào.',
                            icon: LucideIcons.bellOff,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final n = filteredList[index];
                              final isRead = notifProvider.isRead(n.notificationId, n.isRead);

                              return InkWell(
                                onTap: () async {
                                  await notifProvider.markAsRead(n.notificationId);
                                  if (mounted) {
                                    _navigateToTarget(n);
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.white : const Color(0xFFFFF9EE),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isRead ? const Color(0xFFF0E8DC) : const Color(0xFFF0DFBD),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isRead ? const Color(0xFFFAF6F0) : const Color(0xFFFFF0E5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getNotificationIcon(n),
                                          size: 18,
                                          color: isRead ? AppColors.warmTextMuted : AppColors.goldPrimary,
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
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                color: AppColors.warmTextDark,
                                              ),
                                            ),
                                            if (n.content != null && n.content!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                n.content!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12.5, color: AppColors.warmTextMuted),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Text(
                                              Formatters.formatDateTime(n.createdAt),
                                              style: const TextStyle(fontSize: 11, color: AppColors.warmTextMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
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
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary : const Color(0xFFF7F2EA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.goldPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.warmTextMuted,
          ),
        ),
      ),
    );
  }
}
