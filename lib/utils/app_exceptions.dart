import 'package:dio/dio.dart';

enum AppErrorType {
  noInternet,
  timeout,
  serverError,
  notFound,
  rateLimited,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String userMessage;
  final String? technicalDetail;
  final bool isRetryable;

  const AppException({
    required this.type,
    required this.userMessage,
    this.technicalDetail,
    this.isRetryable = false,
  });

  factory AppException.fromDioException(DioException e, {String? context}) {
    final prefix = context != null ? '$context: ' : '';

    switch (e.type) {
      case DioExceptionType.connectionError:
        return AppException(
          type: AppErrorType.noInternet,
          userMessage:
              '${prefix}No internet connection. Please check your network and try again.',
          technicalDetail: e.message,
          isRetryable: true,
        );

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          type: AppErrorType.timeout,
          userMessage:
              '${prefix}Request timed out. The server may be slow — please try again.',
          technicalDetail: e.message,
          isRetryable: true,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return AppException(
            type: AppErrorType.notFound,
            userMessage:
                '${prefix}Data not found. This company may not have filings available.',
            technicalDetail: 'HTTP 404: ${e.requestOptions.uri}',
          );
        }
        if (statusCode == 429) {
          return AppException(
            type: AppErrorType.rateLimited,
            userMessage:
                '${prefix}Too many requests. Please wait a moment and try again.',
            technicalDetail: 'HTTP 429',
            isRetryable: true,
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return AppException(
            type: AppErrorType.serverError,
            userMessage:
                '${prefix}The server is experiencing issues. Please try again later.',
            technicalDetail: 'HTTP $statusCode',
            isRetryable: true,
          );
        }
        return AppException(
          type: AppErrorType.unknown,
          userMessage: '${prefix}An unexpected error occurred (HTTP $statusCode).',
          technicalDetail: 'HTTP $statusCode: ${e.message}',
        );

      case DioExceptionType.unknown:
        if (e.error?.toString().contains('SocketException') == true) {
          return AppException(
            type: AppErrorType.noInternet,
            userMessage:
                '${prefix}No internet connection. Please check your network and try again.',
            technicalDetail: e.error.toString(),
            isRetryable: true,
          );
        }
        return AppException(
          type: AppErrorType.unknown,
          userMessage: '${prefix}Something went wrong. Please try again.',
          technicalDetail: '${e.type}: ${e.message}',
          isRetryable: true,
        );

      default:
        return AppException(
          type: AppErrorType.unknown,
          userMessage: '${prefix}Something went wrong. Please try again.',
          technicalDetail: '${e.type}: ${e.message}',
          isRetryable: true,
        );
    }
  }

  factory AppException.fromGeneric(Object e, {String? context}) {
    if (e is AppException) return e;
    if (e is DioException) {
      return AppException.fromDioException(e, context: context);
    }
    final prefix = context != null ? '$context: ' : '';
    return AppException(
      type: AppErrorType.unknown,
      userMessage: '${prefix}An unexpected error occurred.',
      technicalDetail: e.toString(),
    );
  }

  @override
  String toString() => 'AppException($type): $userMessage [$technicalDetail]';
}
