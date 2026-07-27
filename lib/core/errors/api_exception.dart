class ApiException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  ApiException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}
