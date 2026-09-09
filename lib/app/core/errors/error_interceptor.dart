import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapDioExceptionToAppException(err);
    // Attach normalized AppException to DioException.error
    final modifiedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appException,
      message: appException.message,
    );
    handler.next(modifiedError);
  }

  AppException _mapDioExceptionToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Connection timed out or network error. Please check your connection.',
          details: err.error,
        );

      case DioExceptionType.cancel:
        return const CancelException();

      case DioExceptionType.badResponse:
        return _mapStatusCode(err.response);

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Certificate verification failed.',
          details: err.error,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownException(
          message: err.message ?? 'An unexpected error occurred.',
          details: err.error,
        );
    }
  }

  AppException _mapStatusCode(Response? response) {
    final statusCode = response?.statusCode;
    final message = _extractErrorMessage(response?.data);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message ?? 'Bad request. Please check your input.',
          statusCode: 400,
          details: response?.data,
        );
      case 401:
        return UnauthorizedException(
          message: message ?? 'Unauthorized access. Please login again.',
          statusCode: 401,
          details: response?.data,
        );
      case 403:
        return ForbiddenException(
          message: message ?? 'You do not have permission to access this resource.',
          statusCode: 403,
          details: response?.data,
        );
      case 404:
        return NotFoundException(
          message: message ?? 'Requested resource was not found.',
          statusCode: 404,
          details: response?.data,
        );
      case 422:
        return ValidationException(
          message: message ?? 'Validation error. Please verify the submitted data.',
          statusCode: 422,
          details: response?.data,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: message ?? 'Server error occurred. Please try again later.',
          statusCode: statusCode,
          details: response?.data,
        );
      default:
        return UnknownException(
          message: message ?? 'Error occurred ($statusCode).',
          statusCode: statusCode,
          details: response?.data,
        );
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      if (data['error'] != null) return data['error'].toString();
      if (data['msg'] != null) return data['msg'].toString();
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }
}
