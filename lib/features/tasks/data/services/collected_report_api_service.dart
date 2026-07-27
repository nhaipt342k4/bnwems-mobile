import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class CreateCollectedReportBody {
  final String reportType; // 'INTERNAL' | 'SUPPLIER'
  final String? transactionId;
  final String? notes;
  final List<Map<String, dynamic>> items;

  CreateCollectedReportBody({
    required this.reportType,
    this.transactionId,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportType': reportType,
      if (transactionId != null) 'transactionId': transactionId,
      if (notes != null) 'notes': notes,
      'items': items,
    };
  }
}

class CollectedReportApiService {
  final ApiClient _apiClient;

  CollectedReportApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<CollectedEquipmentReport> create(
    String orderId,
    CreateCollectedReportBody body,
  ) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/mobile/orders/$orderId/collected-reports',
      method: 'POST',
      body: body.toJson(),
    );
    return CollectedEquipmentReport.fromJson(response);
  }

  Future<List<CollectedEquipmentReport>> listByOrderId(String orderId) async {
    final response = await _apiClient.fetchData<List<dynamic>>(
      '/inventory/collected-equipment-reports',
      queryParameters: {'orderId': orderId},
    );
    return response
        .map((row) => CollectedEquipmentReport.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<CollectedEquipmentReport> confirm(String reportId, {String? notes}) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/inventory/collected-equipment-reports/$reportId/confirm',
      method: 'PUT',
      body: {if (notes != null) 'notes': notes},
    );
    return CollectedEquipmentReport.fromJson(response);
  }
}
