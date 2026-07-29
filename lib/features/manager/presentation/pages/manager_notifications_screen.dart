import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

    // Extract ORD-xxx code if present
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo Quản lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                for (final n in notifications) {
                  if (!notifProvider.isRead(n.notificationId, n.isRead)) {
                    notifProvider.markAsRead(n.notificationId);
                  }
                }
              },
              child: const Text('Đọc tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await notifProvider.loadNotifications();
          },
          child: Column(
            children: [
              // Filter Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _filter == 'ALL',
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _filter == 'ALL' ? FontWeight.bold : FontWeight.normal,
                        color: _filter == 'ALL' ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onSelected: (_) => setState(() => _filter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Chưa đọc ($unreadCount)'),
                      selected: _filter == 'UNREAD',
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _filter == 'UNREAD' ? FontWeight.bold : FontWeight.normal,
                        color: _filter == 'UNREAD' ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onSelected: (_) => setState(() => _filter = 'UNREAD'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

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
                            padding: const EdgeInsets.all(16),
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
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.white : Colors.blue.shade50.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isRead ? AppColors.background : AppColors.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getNotificationIcon(n),
                                          size: 18,
                                          color: isRead ? AppColors.textMuted : AppColors.primary,
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
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (n.content != null && n.content!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                n.content!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Text(
                                              Formatters.formatDateTime(n.createdAt),
                                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(top: 4, left: 4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
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
}
