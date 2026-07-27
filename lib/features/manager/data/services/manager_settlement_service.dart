import '../../../../core/network/api_client.dart';
import '../models/settlement.dart';

class ManagerSettlementService {
  final ApiClient _apiClient;

  ManagerSettlementService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /orders/:orderId/settlement
  Future<Settlement?> getOrderSettlement(String orderId) async {
    final result = await _apiClient.fetchData<dynamic>('/orders/$orderId/settlement');
    if (result == null) return null;
    return Settlement.fromJson(result as Map<String, dynamic>);
  }

  /// POST /orders/:orderId/settlement
  Future<Settlement> recordSettlement(
    String orderId, {
    double? additionalFee,
    double? compensation,
    double? discount,
    String? paymentMethod,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (additionalFee != null) body['additionalFee'] = additionalFee;
    if (compensation != null) body['compensation'] = compensation;
    if (discount != null) body['discount'] = discount;
    if (paymentMethod != null && paymentMethod.isNotEmpty) body['paymentMethod'] = paymentMethod;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/orders/$orderId/settlement',
      method: 'POST',
      body: body,
    );

    return Settlement.fromJson(result);
  }

  /// PUT /settlements/:settlementId/confirm
  Future<Settlement> confirmSettlement(
    String settlementId, {
    required String status,
    String? notes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/settlements/$settlementId/confirm',
      method: 'PUT',
      body: body,
    );

    return Settlement.fromJson(result);
  }
}
