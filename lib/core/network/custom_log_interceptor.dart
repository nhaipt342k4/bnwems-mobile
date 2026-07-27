import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('--------------------------------------------------', name: 'NETWORK');
    developer.log('➡️ [REQUEST] ${options.method} => ${options.uri}', name: 'NETWORK');
    if (options.headers.isNotEmpty) {
      developer.log('Headers: ${options.headers}', name: 'NETWORK');
    }
    if (options.queryParameters.isNotEmpty) {
      developer.log('Query: ${options.queryParameters}', name: 'NETWORK');
    }
    if (options.data != null) {
      developer.log('Body: ${options.data}', name: 'NETWORK');
    }
    developer.log('--------------------------------------------------', name: 'NETWORK');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log('--------------------------------------------------', name: 'NETWORK');
    developer.log('✅ [RESPONSE] ${response.statusCode} <= ${response.requestOptions.uri}', name: 'NETWORK');
    developer.log('Data: ${response.data}', name: 'NETWORK');
    developer.log('--------------------------------------------------', name: 'NETWORK');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log('--------------------------------------------------', name: 'NETWORK');
    developer.log('❌ [ERROR] ${err.response?.statusCode} <= ${err.requestOptions.uri}', name: 'NETWORK');
    developer.log('Message: ${err.message}', name: 'NETWORK');
    if (err.response?.data != null) {
      developer.log('Error Data: ${err.response?.data}', name: 'NETWORK');
    }
    developer.log('--------------------------------------------------', name: 'NETWORK');
    super.onError(err, handler);
  }
}
