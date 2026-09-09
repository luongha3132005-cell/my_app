import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_exception.dart';

class ErrorHandler {
  ErrorHandler._();

  static AppException normalize(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      if (error.error is AppException) {
        return error.error as AppException;
      }
      return UnknownException(
        message: error.message ?? 'An unexpected network error occurred.',
        statusCode: error.response?.statusCode,
        details: error.response?.data,
      );
    }

    if (error is Exception) {
      return UnknownException(
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }

    return UnknownException(
      message: error?.toString() ?? 'An unknown error occurred.',
    );
  }

  static void handle(
    dynamic error, {
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final appException = normalize(error);

    if (showSnackbar && Get.isSnackbarOpen != true) {
      Get.snackbar(
        'error_title'.tr,
        appException.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error_outline, color: Colors.white),
        mainButton: onRetry != null
            ? TextButton(
                onPressed: () {
                  Get.closeCurrentSnackbar();
                  onRetry();
                },
                child: Text(
                  'retry'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      );
    }
  }
}
