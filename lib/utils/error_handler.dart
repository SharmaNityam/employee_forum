import 'package:dio/dio.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.connectionTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioErrorType.badResponse:
          return _handleStatusCode(error.response?.statusCode);
        case DioErrorType.cancel:
          return 'Request cancelled';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return error.toString();
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Server error';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}