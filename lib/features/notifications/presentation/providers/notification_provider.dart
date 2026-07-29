import 'package:flutter/material.dart';
import '../../../tasks/data/models/work_task_models.dart';
import '../../../tasks/data/services/notification_api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _apiService;

  List<UserNotification> _notifications = [];
  final Set<String> _readNotifIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<UserNotification> get notifications => _notifications;
  Set<String> get readNotifIds => _readNotifIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead && !_readNotifIds.contains(n.notificationId)).length;

  NotificationProvider({NotificationApiService? apiService})
      : _apiService = apiService ?? NotificationApiService();

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _apiService.listMine();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isRead(String notificationId, bool defaultStatus) {
    if (_readNotifIds.contains(notificationId)) return true;
    return defaultStatus;
  }

  Future<void> markAsRead(String notificationId) async {
    _readNotifIds.add(notificationId);
    final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index >= 0) {
      final current = _notifications[index];
      _notifications[index] = UserNotification(
        notificationId: current.notificationId,
        userId: current.userId,
        title: current.title,
        content: current.content,
        type: current.type,
        isRead: true,
        createdAt: current.createdAt,
      );
    }
    notifyListeners();

    if (!notificationId.startsWith('plan_')) {
      try {
        final updated = await _apiService.markAsRead(notificationId);
        final idx = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (idx >= 0) {
          _notifications[idx] = updated;
          notifyListeners();
        }
      } catch (_) {}
    }
  }
}
