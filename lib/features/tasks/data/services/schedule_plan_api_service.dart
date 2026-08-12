import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class SchedulePlanApiService {
  final ApiClient _apiClient;

  SchedulePlanApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Lưu ý: KHÔNG còn tham số assigneeUserId. Với app nhân viên, server tự giới hạn danh sách theo token
  // (role STAFF chỉ nhận lịch của đơn mình được phân công) — client không cần (và không nên) tự truyền
  // assigneeUserId nữa. Bộ lọc "của tôi" đã được enforce ở backend.
  Future<List<SchedulePlan>> list({
    String? orderId,
    SchedulePlanStatus? status,
    String? taskId,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (orderId != null) query['orderId'] = orderId;
    if (status != null && status != 'ALL') query['status'] = status;
    if (taskId != null) query['taskId'] = taskId;
    if (dateFrom != null) query['dateFrom'] = dateFrom;
    if (dateTo != null) query['dateTo'] = dateTo;
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final response = await _apiClient.fetchData<List<dynamic>>(
      '/schedule-plans',
      queryParameters: query,
    );

    return response
        .map((item) => SchedulePlan.fromDtoJson(item as Map<String, dynamic>))
        .toList();
  }

  // Các lịch mà chính người dùng (theo token) đang check-in dở, chưa check-out — cho card "việc đang làm"
  // ở trang chủ. Server tự lọc theo user, không cần truyền tham số.
  Future<List<SchedulePlan>> getActiveCheckIns() async {
    final response = await _apiClient.fetchData<List<dynamic>>(
      '/schedule-plans/active',
    );
    return response
        .map((item) => SchedulePlan.fromDtoJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SchedulePlan> getById(String planId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId',
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<SchedulePlan> checkIn(
    String planId,
    String userId, {
    String? checkInEvidenceId,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{};
    if (checkInEvidenceId != null) body['checkInEvidenceId'] = checkInEvidenceId;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/assignees/$userId/check-in',
      method: 'POST',
      body: body,
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<SchedulePlan> checkOut(
    String planId,
    String userId, {
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/assignees/$userId/check-out',
      method: 'POST',
      body: body,
    );
    return SchedulePlan.fromDtoJson(response);
  }

  // Gắn TẤT CẢ ảnh minh chứng cho lịch (BE nhận mảng evidenceIds, thay thế trọn bộ trong 1 lần gọi).
  Future<SchedulePlan> patchEvidence(String planId, List<String> evidenceIds) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/evidence',
      method: 'PATCH',
      body: {'evidenceIds': evidenceIds},
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<SchedulePlan> patchStatus(
    String planId,
    SchedulePlanStatus status, {
    String? notes,
    String? evidenceId,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null) body['notes'] = notes;
    if (evidenceId != null) body['evidenceId'] = evidenceId;

    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/status',
      method: 'PATCH',
      body: body,
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<void> warehouseMovement(
    String planId,
    List<Map<String, dynamic>> items, {
    String? notes,
  }) async {
    await _apiClient.fetchData(
      '/schedule-plans/$planId/warehouse-movement',
      method: 'POST',
      body: {
        'items': items,
        if (notes != null) 'notes': notes,
      },
    );
  }
}
