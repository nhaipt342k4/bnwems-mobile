import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class SchedulePlanApiService {
  final ApiClient _apiClient;

  SchedulePlanApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<SchedulePlan>> list({
    String? orderId,
    SchedulePlanStatus? status,
    String? taskId,
    String? dateFrom,
    String? dateTo,
    String? assigneeUserId,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (orderId != null) query['orderId'] = orderId;
    if (status != null && status != 'ALL') query['status'] = status;
    if (taskId != null) query['taskId'] = taskId;
    if (dateFrom != null) query['dateFrom'] = dateFrom;
    if (dateTo != null) query['dateTo'] = dateTo;
    if (assigneeUserId != null) query['assigneeUserId'] = assigneeUserId;
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

  Future<SchedulePlan> getById(String planId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId',
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<SchedulePlan> checkIn(String planId, String userId, {String? checkInEvidenceId}) async {
    final body = <String, dynamic>{};
    if (checkInEvidenceId != null) body['checkInEvidenceId'] = checkInEvidenceId;

    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/assignees/$userId/check-in',
      method: 'POST',
      body: body,
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<SchedulePlan> checkOut(String planId, String userId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/assignees/$userId/check-out',
      method: 'POST',
    );
    return SchedulePlan.fromDtoJson(response);
  }

  Future<SchedulePlan> patchEvidence(String planId, String evidenceId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/schedule-plans/$planId/evidence',
      method: 'PATCH',
      body: {'evidenceId': evidenceId},
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
