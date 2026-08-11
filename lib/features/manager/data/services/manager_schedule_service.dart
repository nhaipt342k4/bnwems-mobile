import '../../../../core/network/api_client.dart';
import '../models/manager_schedule_plan.dart';

class ManagerScheduleService {
  final ApiClient _apiClient;

  ManagerScheduleService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /schedule-plans
  Future<List<ManagerSchedulePlan>> getSchedulePlans({
    int? page,
    int? limit,
    String? orderId,
    String? assignedTo,
    String? status,
    String? date,
    String? dateFrom,
    String? dateTo,
    String? dateMode,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (orderId != null && orderId.isNotEmpty) query['orderId'] = orderId;
    if (assignedTo != null && assignedTo.isNotEmpty) query['assignedTo'] = assignedTo;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (date != null && date.isNotEmpty) query['date'] = date;
    if (dateFrom != null && dateFrom.isNotEmpty) query['dateFrom'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) query['dateTo'] = dateTo;
    if (dateMode != null && dateMode.isNotEmpty) query['dateMode'] = dateMode;

    final result = await _apiClient.fetchData<List<dynamic>>(
      '/schedule-plans',
      queryParameters: query,
    );

    return result.map((item) => ManagerSchedulePlan.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// GET /schedule-plans/:planId — manager có quyền đọc mọi plan (BE không scope manager).
  Future<ManagerSchedulePlan> getSchedulePlanById(String planId) async {
    final result = await _apiClient.fetchData<Map<String, dynamic>>('/schedule-plans/$planId');
    return ManagerSchedulePlan.fromJson(result);
  }
}
