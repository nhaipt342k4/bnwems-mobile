/// Khảo sát hiện trường staff đã nộp, đang CHỜ manager xác nhận (status SUBMITTED / NEEDS_REVIEW).
class SurveyPending {
  final String surveyId;
  final String reportCode;
  final String orderId;
  final String orderCode;
  final String customerName;
  final String? eventName;
  final String surveyDate;
  final String location;
  final String status; // 'SUBMITTED' | 'NEEDS_REVIEW'
  final String reportedByName;

  SurveyPending({
    required this.surveyId,
    required this.reportCode,
    required this.orderId,
    required this.orderCode,
    required this.customerName,
    this.eventName,
    required this.surveyDate,
    required this.location,
    required this.status,
    required this.reportedByName,
  });

  factory SurveyPending.fromJson(Map<String, dynamic> json) {
    return SurveyPending(
      surveyId: json['surveyId']?.toString() ?? '',
      reportCode: json['reportCode']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      eventName: json['eventName']?.toString(),
      surveyDate: json['surveyDate']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SUBMITTED',
      reportedByName: json['reportedByName']?.toString() ?? '',
    );
  }
}
