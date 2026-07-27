import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_storage_service.dart';
import 'custom_log_interceptor.dart';

class ApiResult<T> {
  final T data;
  final ApiMeta? meta;

  ApiResult({required this.data, this.meta});
}

class ApiMeta {
  final int? page;
  final int? limit;
  final int totalItems;
  final int? totalPages;

  ApiMeta({
    this.page,
    this.limit,
    required this.totalItems,
    this.totalPages,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: json['totalPages'] as int?,
    );
  }
}

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storageService;

  Dio get dio => _dio;

  ApiClient({
    SecureStorageService? storageService,
    Dio? dio,
  }) : _storageService = storageService ?? SecureStorageService() {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Custom Log Interceptor using developer.log
    _dio.interceptors.add(CustomLogInterceptor());
  }

  Future<ApiResult<T>> fetchEnvelope<T>(
    String path, {
    String method = 'GET',
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    T Function(dynamic data)? mapper,
  }) async {
    try {
      final options = Options(
        method: method,
        contentType: isFormData ? 'multipart/form-data' : 'application/json',
      );

      final response = await _dio.request(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final success = responseData['success'] == true;
        if (!success) {
          final errorObj = responseData['error'] as Map<String, dynamic>?;
          throw ApiException(
            code: errorObj?['code']?.toString() ?? 'API_ERROR',
            message: errorObj?['message']?.toString() ?? 'Đã có lỗi xảy ra',
            details: errorObj?['details'],
          );
        }

        final rawData = responseData['data'];
        final T mappedData = mapper != null ? mapper(rawData) : rawData as T;
        ApiMeta? meta;
        if (responseData['meta'] != null) {
          meta = ApiMeta.fromJson(responseData['meta'] as Map<String, dynamic>);
        }

        return ApiResult(data: mappedData, meta: meta);
      }

      final T mappedData = mapper != null ? mapper(responseData) : responseData as T;
      return ApiResult(data: mappedData);
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final errorMap = e.response!.data as Map<String, dynamic>;
        final errorObj = errorMap['error'] as Map<String, dynamic>?;
        throw ApiException(
          code: errorObj?['code']?.toString() ?? e.response?.statusCode?.toString() ?? 'HTTP_ERROR',
          message: errorObj?['message']?.toString() ?? 'Yêu cầu không thành công (${e.response?.statusCode})',
          details: errorObj?['details'],
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.error is SocketException) {
        throw ApiException(
          code: 'NETWORK_ERROR',
          message: 'Không thể kết nối tới máy chủ — kiểm tra kết nối mạng hoặc backend.',
        );
      }
      throw ApiException(
        code: 'UNKNOWN_ERROR',
        message: e.message ?? 'Đã có lỗi không xác định xảy ra.',
      );
    }
  }

  Future<T> fetchData<T>(
    String path, {
    String method = 'GET',
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    T Function(dynamic data)? mapper,
  }) async {
    final result = await fetchEnvelope<T>(
      path,
      method: method,
      body: body,
      queryParameters: queryParameters,
      isFormData: isFormData,
      mapper: mapper,
    );
    return result.data;
  }
}
