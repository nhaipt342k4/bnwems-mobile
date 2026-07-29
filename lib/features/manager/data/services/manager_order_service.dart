import '../../../../core/network/api_client.dart';
import '../models/manager_order.dart';

class ManagerOrderService {
  final ApiClient _apiClient;

  ManagerOrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /orders
  Future<List<ManagerOrder>> getOrders({
    int? page,
    int? limit,
    String? orderStatus,
    String? paymentStatus,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (orderStatus != null && orderStatus.isNotEmpty) query['orderStatus'] = orderStatus;
    if (paymentStatus != null && paymentStatus.isNotEmpty) query['paymentStatus'] = paymentStatus;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final result = await _apiClient.fetchData<dynamic>(
      '/orders',
      queryParameters: query,
    );

    if (result == null) return [];
    List<dynamic> list;
    if (result is List) {
      list = result;
    } else if (result is Map && result['data'] is List) {
      list = result['data'] as List;
    } else {
      list = [];
    }

    return list.map((item) => ManagerOrder.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// GET /orders/:id
  Future<ManagerOrder> getOrder(String id) async {
    final result = await _apiClient.fetchData<Map<String, dynamic>>('/orders/$id');
    return ManagerOrder.fromJson(result);
  }

  /// PUT /orders/:id/status
  Future<ManagerOrder> updateOrderStatus(
    String id, {
    required String orderStatus,
    String? cancelReason,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'orderStatus': orderStatus,
    };
    if (cancelReason != null && cancelReason.isNotEmpty) body['cancelReason'] = cancelReason;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/orders/$id/status',
      method: 'PUT',
      body: body,
    );

    return ManagerOrder.fromJson(result);
  }
}
