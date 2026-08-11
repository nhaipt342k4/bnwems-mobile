import '../../../../core/network/api_client.dart';
import '../models/survey_pending.dart';

class ManagerSurveyService {
  final ApiClient _apiClient;

  ManagerSurveyService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<SurveyPending>> _list(String status) async {
    final result = await _apiClient.fetchData<List<dynamic>>(
      '/survey-reports',
      queryParameters: {'status': status, 'limit': 100},
    );
    return result.map((e) => SurveyPending.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Các khảo sát đang chờ manager xác nhận (2 trạng thái confirm được: SUBMITTED, NEEDS_REVIEW).
  Future<List<SurveyPending>> getPendingSurveys() async {
    final results = await Future.wait([_list('SUBMITTED'), _list('NEEDS_REVIEW')]);
    return [...results[0], ...results[1]];
  }

  /// PUT /survey-reports/:id/confirm — manager xác nhận khảo sát.
  Future<void> confirmSurvey(String surveyId) async {
    await _apiClient.fetchData<Map<String, dynamic>>(
      '/survey-reports/$surveyId/confirm',
      method: 'PUT',
      body: {'status': 'CONFIRMED'},
    );
  }
}
