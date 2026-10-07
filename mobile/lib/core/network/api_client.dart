import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator to host
  static String get baseUrl => defaultBaseUrl;
  late final Dio dio;

  ApiClient({String baseUrl = defaultBaseUrl}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Please check your internet connection and try again.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          String? serverDetail;
          if (data is Map && data.containsKey('detail')) {
            serverDetail = data['detail'].toString();
          }
          if (statusCode == 401) {
            return serverDetail ?? 'Invalid email or password. Please try again.';
          } else if (statusCode == 400) {
            return serverDetail ?? 'Invalid request. Please check your inputs.';
          } else if (statusCode == 404) {
            return serverDetail ?? 'The requested resource was not found.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server error occurred ($statusCode). Please try again shortly.';
          }
          return serverDetail ?? 'Request failed with status code $statusCode.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error occurred. Please check your connection.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
