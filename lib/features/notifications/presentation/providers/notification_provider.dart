import 'package:flutter/material.dart';
import '../../../tasks/data/models/work_task_models.dart';
import '../../../tasks/data/services/notification_api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _apiService;

  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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

  Future<void> markAsRead(String notificationId) async {
    try {
      final updated = await _apiService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index >= 0) {
        _notifications[index] = updated;
        notifyListeners();
      }
    } catch (_) {}
  }
}
