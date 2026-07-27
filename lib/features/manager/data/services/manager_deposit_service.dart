import '../../../../core/network/api_client.dart';
import '../models/deposit.dart';

class ManagerDepositService {
  final ApiClient _apiClient;

  ManagerDepositService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /orders/:orderId/deposits
  Future<List<Deposit>> getOrderDeposits(String orderId) async {
    final result = await _apiClient.fetchData<List<dynamic>>('/orders/$orderId/deposits');
    return result.map((item) => Deposit.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// POST /orders/:orderId/deposits
  Future<Deposit> createOrderDeposit(
    String orderId, {
    required double amount,
    String? paymentMethod,
    String? notes,
    String? dueDate,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
    };
    if (paymentMethod != null && paymentMethod.isNotEmpty) body['paymentMethod'] = paymentMethod;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (dueDate != null && dueDate.isNotEmpty) body['dueDate'] = dueDate;

    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/orders/$orderId/deposits',
      method: 'POST',
      body: body,
    );

    return Deposit.fromJson(result);
  }

  /// PUT /deposits/:depositId
  Future<Deposit> updateDepositStatus(String depositId, {required String status}) async {
    final result = await _apiClient.fetchData<Map<String, dynamic>>(
      '/deposits/$depositId',
      method: 'PUT',
      body: {'status': status},
    );

    return Deposit.fromJson(result);
  }
}
