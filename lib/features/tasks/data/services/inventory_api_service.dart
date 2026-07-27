import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class InventoryApiService {
  final ApiClient _apiClient;

  InventoryApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<WorkTaskItem>> getPicklist(String orderId) async {
    final response = await _apiClient.fetchData<List<dynamic>>(
      '/inventory/picklist/$orderId',
    );

    return response
        .map((row) => row as Map<String, dynamic>)
        .where((row) => row['source'] == 'INTERNAL')
        .map((row) => WorkTaskItem.fromJson(row))
        .toList();
  }
}
