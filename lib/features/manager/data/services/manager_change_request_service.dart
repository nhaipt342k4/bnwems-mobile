import '../../../../core/network/api_client.dart';
import '../models/change_request.dart';

class ManagerChangeRequestService {
  final ApiClient _apiClient;

  ManagerChangeRequestService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /change-requests
  Future<List<ChangeRequest>> getChangeRequests({
    String? orderId,
    String? status,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (orderId != null && orderId.isNotEmpty) query['orderId'] = orderId;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final result = await _apiClient.fetchData<List<dynamic>>(
      '/change-requests',
      queryParameters: query,
    );

    return result.map((item) => ChangeRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// PUT /change-requests/:id/approve
  Future<ChangeRequest> approveChangeRequest(String id, String status) async {
    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/change-requests/$id/approve',
      method: 'PUT',
      body: {'status': status},
    );

    return ChangeRequest.fromJson(result);
  }
}
