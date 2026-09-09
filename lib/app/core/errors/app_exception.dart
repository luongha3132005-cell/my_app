class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection or connection timed out.',
    super.statusCode,
    super.details,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized access. Please login again.',
    super.statusCode = 401,
    super.details,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access forbidden. You do not have permission.',
    super.statusCode = 403,
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Requested resource was not found.',
    super.statusCode = 404,
    super.details,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Validation error occurred.',
    super.statusCode = 422,
    super.details,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Server encountered an error. Please try again later.',
    super.statusCode = 500,
    super.details,
  });
}

class CancelException extends AppException {
  const CancelException({
    super.message = 'Request was cancelled.',
    super.statusCode,
    super.details,
  });
}

class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
    super.details,
  });
}
