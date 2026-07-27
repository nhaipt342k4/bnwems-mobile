import '../../../../core/network/api_client.dart';
import '../models/inventory.dart';
import '../models/collected_equipment_report.dart';

class ManagerInventoryService {
  final ApiClient _apiClient;

  ManagerInventoryService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /inventory
  Future<List<InventoryRow>> getInventory({
    String? itemId,
    String? search,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (itemId != null && itemId.isNotEmpty) query['itemId'] = itemId;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final result = await _apiClient.fetchData<List<dynamic>>(
      '/inventory',
      queryParameters: query,
    );

    return result.map((item) => InventoryRow.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// GET /inventory/return-reports
  Future<List<CollectedEquipmentReport>> getReturnReports({
    String? status,
    String? orderId,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (orderId != null && orderId.isNotEmpty) query['orderId'] = orderId;
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final result = await _apiClient.fetchData<List<dynamic>>(
      '/inventory/return-reports',
      queryParameters: query,
    );

    return result.map((item) => CollectedEquipmentReport.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// GET /inventory/return-reports/:id
  Future<CollectedEquipmentReport> getReturnReport(String reportId) async {
    final result = await _apiClient.fetchData<Map<String, dynamic>>('/inventory/return-reports/$reportId');
    return CollectedEquipmentReport.fromJson(result);
  }

  /// PUT /inventory/return-reports/:id/confirm
  Future<CollectedEquipmentReport> confirmReturnReport(String reportId, {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/inventory/return-reports/$reportId/confirm',
      method: 'PUT',
      body: body,
    );

    return CollectedEquipmentReport.fromJson(result);
  }
}
