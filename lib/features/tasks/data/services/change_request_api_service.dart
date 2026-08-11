import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

/// 1 dòng trong yêu cầu đổi thiết bị (hiện trường).
class ChangeRequestItemInput {
  final String catalogItemId;
  final int quantity;
  final String action; // 'add' | 'remove'

  ChangeRequestItemInput({
    required this.catalogItemId,
    required this.quantity,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'catalogItemId': catalogItemId,
        'quantity': quantity,
        'action': action,
      };
}

/// Gửi yêu cầu đổi/bổ sung/bớt thiết bị từ hiện trường (LEAD) → Manager duyệt.
/// BE: POST /orders/:orderId/change-requests (requireRole MANAGER, STAFF).
class ChangeRequestApiService {
  final ApiClient _apiClient;

  ChangeRequestApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<void> create(
    String orderId, {
    required String type, // 'add' | 'remove' | 'replace'
    required List<ChangeRequestItemInput> items,
  }) async {
    await _apiClient.fetchData<Map<String, dynamic>>(
      '/orders/$orderId/change-requests',
      method: 'POST',
      body: {
        'type': type,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
  }

  /// Danh mục thiết bị (để chọn khi THÊM/THAY). GET /inventory — mọi role đăng nhập đọc được.
  Future<List<WorkTaskItem>> listCatalog() async {
    final response = await _apiClient.fetchData<List<dynamic>>(
      '/inventory',
      queryParameters: {'limit': 200},
    );
    return response.map((row) => WorkTaskItem.fromJson(row as Map<String, dynamic>)).toList();
  }
}
