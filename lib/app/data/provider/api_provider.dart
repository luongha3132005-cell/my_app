import 'package:dio/dio.dart';
import '../../core/config/flavor_config.dart';
import '../../core/errors/error_handler.dart';
import '../../core/errors/error_interceptor.dart';
import '../../core/loading/loading_service.dart';
import 'api_service.dart';

/// Centralized networking provider encapsulating Dio & Retrofit
class ApiProvider {
  late final Dio dio;
  late final ApiService apiService;
  String? _authToken;

  ApiProvider({Dio? customDio}) {
    dio = customDio ?? _createDio();
    apiService = ApiService(dio, baseUrl: FlavorConfig.instance.baseUrl);
  }

  /// Create and configure Dio instance
  Dio _createDio() {
    final baseOptions = BaseOptions(
      baseUrl: FlavorConfig.instance.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final dioInstance = Dio(baseOptions);

    // Auth header interceptor
    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
      ),
    );

    // Error normalization interceptor
    dioInstance.interceptors.add(ErrorInterceptor());

    // Logging interceptor for debug/flavor
    if (FlavorConfig.instance.enableLogging) {
      dioInstance.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }

    return dioInstance;
  }

  /// Update bearer authorization token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear stored authorization token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Safe execution wrapper providing global loading, error handling, and optional retry
  Future<T> safeCall<T>(
    Future<T> Function() call, {
    bool showLoading = true,
    String? loadingMessage,
    bool handleErrors = true,
    Future<void> Function()? onRetry,
  }) async {
    if (showLoading) {
      LoadingService.to.show(message: loadingMessage);
    }

    try {
      final result = await call();
      return result;
    } catch (error) {
      final appException = ErrorHandler.normalize(error);

      if (handleErrors) {
        ErrorHandler.handle(
          appException,
          onRetry: onRetry != null
              ? () => safeCall(
                    call,
                    showLoading: showLoading,
                    loadingMessage: loadingMessage,
                    handleErrors: handleErrors,
                    onRetry: onRetry,
                  )
              : null,
        );
      }
      throw appException;
    } finally {
      if (showLoading) {
        LoadingService.to.hide();
      }
    }
  }
}
