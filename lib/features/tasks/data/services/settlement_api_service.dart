import '../../../../core/network/api_client.dart';
import '../models/work_task_models.dart';

class CreateSettlementBody {
  final num additionalFee;
  final num compensation;
  final num discount;
  final String? paymentMethod; // 'cash' | 'bank_transfer'
  final String? qrCodeUrl;
  final String? notes;

  CreateSettlementBody({
    required this.additionalFee,
    required this.compensation,
    required this.discount,
    this.paymentMethod,
    this.qrCodeUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'additionalFee': additionalFee,
      'compensation': compensation,
      'discount': discount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (notes != null) 'notes': notes,
    };
  }
}

class SettlementApiService {
  final ApiClient _apiClient;

  SettlementApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<String> create(String orderId, CreateSettlementBody body) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/orders/$orderId/settlement',
      method: 'POST',
      body: body.toJson(),
    );
    return response['settlementId']?.toString() ?? '';
  }

  Future<Settlement?> getByOrderId(String orderId) async {
    final response = await _apiClient.fetchData<dynamic>(
      '/orders/$orderId/settlement',
    );
    if (response == null || response is! Map<String, dynamic>) return null;
    return Settlement.fromJson(response);
  }

  Future<Settlement> markPaid(String settlementId, String evidenceId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/settlements/$settlementId/mark-paid',
      method: 'PUT',
      body: {'evidenceId': evidenceId},
    );
    return Settlement.fromJson(response);
  }
}
