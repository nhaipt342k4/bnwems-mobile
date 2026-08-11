import '../../../../core/network/api_client.dart';

class CreateSurveyReportBody {
  final String orderId;
  final String? planId;
  final String surveyDate;
  final String location;
  final double area;
  final double length;
  final double width;
  final String entrance;
  final String? siteConstraints;
  final String? proposedItems;
  final String? notes;
  final List<String> evidenceIds;

  CreateSurveyReportBody({
    required this.orderId,
    this.planId,
    required this.surveyDate,
    required this.location,
    required this.area,
    required this.length,
    required this.width,
    required this.entrance,
    this.siteConstraints,
    this.proposedItems,
    this.notes,
    this.evidenceIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      if (planId != null && planId!.trim().isNotEmpty) 'planId': planId,
      'surveyDate': surveyDate,
      'location': location,
      'area': area,
      'length': length,
      'width': width,
      'entrance': entrance,
      if (siteConstraints != null && siteConstraints!.trim().isNotEmpty) 'siteConstraints': siteConstraints,
      if (proposedItems != null && proposedItems!.trim().isNotEmpty) 'proposedItems': proposedItems,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
      if (evidenceIds.isNotEmpty) 'evidenceIds': evidenceIds,
    };
  }
}

class SurveyReportApiService {
  final ApiClient _apiClient;

  SurveyReportApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> create(CreateSurveyReportBody body) async {
    return await _apiClient.fetchData<Map<String, dynamic>>(
      '/survey-reports',
      method: 'POST',
      body: body.toJson(),
    );
  }

  Future<List<Map<String, dynamic>>> listByPlanId(String planId) async {
    final response = await _apiClient.fetchData<List<dynamic>>(
      '/survey-reports',
      queryParameters: {'planId': planId},
    );
    return response
        .map((row) => row as Map<String, dynamic>)
        .where((row) => row['planId'] == planId)
        .toList();
  }

  // Chi tiết 1 báo cáo khảo sát (đầy đủ diện tích/lối vào/evidenceIds) — dùng để hiển thị cho Manager.
  Future<Map<String, dynamic>> getById(String surveyId) async {
    return await _apiClient.fetchData<Map<String, dynamic>>('/survey-reports/$surveyId');
  }
}
