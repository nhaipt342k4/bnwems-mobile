import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class SupplierTransactionApiService {
  final ApiClient _apiClient;

  SupplierTransactionApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<SupplierTransaction>> listWithItems(String orderId) async {
    final summaries = await _apiClient.fetchData<List<dynamic>>(
      '/supplier-transactions',
      queryParameters: {'orderId': orderId},
    );

    final List<SupplierTransaction> results = [];
    for (final summary in summaries) {
      final summaryMap = summary as Map<String, dynamic>;
      final transactionId = summaryMap['transactionId']?.toString() ?? '';
      if (transactionId.isNotEmpty) {
        final detail = await _apiClient.fetchData<Map<String, dynamic>>(
          '/supplier-transactions/$transactionId',
        );
        results.add(SupplierTransaction.fromJson(detail));
      }
    }
    return results;
  }

  Future<SupplierTransactionItem> receiveItem(
    String transactionId,
    String stItemId,
    int receivedQuantity,
  ) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/supplier-transactions/$transactionId/items/$stItemId',
      method: 'PATCH',
      body: {'receivedQuantity': receivedQuantity},
    );
    return SupplierTransactionItem.fromJson(response);
  }

  /// Xác nhận "đã nhận" cả giao dịch (Đã duyệt → Đã nhận). BE tự giới hạn: chỉ LEAD của đơn, chỉ khi
  /// status=APPROVED, chặn nếu đã thanh toán. Trả về giao dịch đã cập nhật.
  Future<SupplierTransaction> confirmReceived(String transactionId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/supplier-transactions/$transactionId/receive',
      method: 'POST',
    );
    return SupplierTransaction.fromJson(response);
  }
}
