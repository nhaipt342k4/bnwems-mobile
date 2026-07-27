import '../../../../core/network/api_client.dart';

class CreateDepositBody {
  final num amount;
  final String? dueDate;
  final String? paymentMethod; // 'cash' | 'bank_transfer'
  final String? qrCodeUrl;
  final String? evidenceId;
  final String? notes;

  CreateDepositBody({
    required this.amount,
    this.dueDate,
    this.paymentMethod,
    this.qrCodeUrl,
    this.evidenceId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      if (dueDate != null) 'dueDate': dueDate,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (evidenceId != null) 'evidenceId': evidenceId,
      if (notes != null) 'notes': notes,
    };
  }
}

class DepositApiService {
  final ApiClient _apiClient;

  DepositApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> create(String orderId, CreateDepositBody body) async {
    return await _apiClient.fetchData<Map<String, dynamic>>(
      '/orders/$orderId/deposits',
      method: 'POST',
      body: body.toJson(),
    );
  }

  Future<List<Map<String, dynamic>>> list(String orderId) async {
    final response = await _apiClient.fetchData<List<dynamic>>(
      '/orders/$orderId/deposits',
    );
    return response.map((row) => row as Map<String, dynamic>).toList();
  }
}
