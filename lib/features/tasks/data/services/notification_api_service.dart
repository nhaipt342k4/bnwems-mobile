import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<UserNotification>> listMine() async {
    final response = await _apiClient.fetchData<List<dynamic>>('/notifications');
    return response
        .map((item) => UserNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserNotification> markAsRead(String notificationId) async {
    final encodedId = Uri.encodeComponent(notificationId);
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/notifications/$encodedId/read',
      method: 'PATCH',
    );
    return UserNotification.fromJson(response);
  }

  Future<void> registerDeviceToken(String deviceToken) async {
    await _apiClient.fetchData(
      '/notifications/device-token',
      method: 'POST',
      body: {'deviceToken': deviceToken},
    );
  }
}
