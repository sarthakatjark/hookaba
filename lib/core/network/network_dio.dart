import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final Dio _dio;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  DioClient(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    CacheStore cacheStore =
        MemCacheStore(maxSize: 10485760, maxEntrySize: 1048576);
    CacheOptions? cacheOptions = CacheOptions(
      store: cacheStore,
      hitCacheOnErrorCodes: [], // for offline behaviour
    );

    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final requireAuth = options.extra['requireAuth'] ?? true;
        if (!requireAuth) {
          handler.next(options);
          return;
        }
        String? token = await _secureStorage.read(key: 'user_token');
        if (token == null) {
          log("Token is null or invalid. Request not sent.");
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: "Invalid token. Request cancelled.",
            ),
          );
        }
        options.headers['Authorization'] = token;
        handler.next(options);
      },
    ));

    _dio.interceptors.add(LogInterceptor(responseBody: true)); // For logging
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
    bool requireAuth = true,
  }) async {
    options ??= Options();
    options.extra = {...?options.extra, 'requireAuth': requireAuth};
    try {
      return await _dio.get(endpoint,
          queryParameters: queryParams, options: options);
    } on DioException catch (e) {
      handleError(e);
      rethrow;
    }
  }

  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Options? options,
    bool requireAuth = true,
  }) async {
    options ??= Options();
    options.extra = {...?options.extra, 'requireAuth': requireAuth};
    try {
      return await _dio.post(endpoint, data: data, options: options);
    } on DioException catch (e) {
      log('dfdfsf $e');
      handleError(e);
      rethrow;
    }
  }

  Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? data,
    Options? options,
    bool requireAuth = true,
  }) async {
    options ??= Options();
    options.extra = {...?options.extra, 'requireAuth': requireAuth};
    try {
      return await _dio.put(endpoint, data: data, options: options);
    } on DioException catch (e) {
      handleError(e);
      rethrow;
    }
  }

  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    Options? options,
    bool requireAuth = true,
  }) async {
    options ??= Options();
    options.extra = {...?options.extra, 'requireAuth': requireAuth};
    try {
      return await _dio.delete(endpoint, data: data, options: options);
    } on DioException catch (e) {
      handleError(e);
      rethrow;
    }
  }

  // File upload method
  Future<Response> uploadFile(String endpoint,
      {required File file,
      required String fieldName,
      Map<String, dynamic>? additionalData,
      Options? options,
      bool requireAuth = true,
      }) async {
    options ??= Options();
    options.extra = {...?options.extra, 'requireAuth': requireAuth};
    try {
      // Create FormData
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        ...?additionalData,
      });

      return await _dio.post(endpoint, data: formData, options: options);
    } on DioException catch (e) {
      handleError(e);
      rethrow;
    }
  }

  void handleError(DioException e) {
    // Check if the error has an associated response from the server
    if (e.response != null) {
      switch (e.response?.statusCode) {
        case 200:
          log("Good request: ${e.response?.data}");

          break;
        case 400:
          log("Bad request: ${e.response?.data}");
          break;
        case 401:
          log("Unauthorized: Please check your credentials.");
          break;
        case 403:
          log("Forbidden: You do not have permission to access this resource.");
          break;
        case 404:
          log("Not found: The resource was not found.");
          break;
        case 500:
          log("Internal Server Error: Please try again later.");
          break;
        default:
          log("Received invalid status code: ${e.response?.statusCode}");
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      log("Connection timed out. Please check your internet connection.");
    } else if (e.type == DioExceptionType.receiveTimeout) {
      log("Receive timeout in connection with API server.");
    } else if (e.type == DioExceptionType.badCertificate) {
      log("Bad certificate received, possible SSL error.");
    } else if (e.type == DioExceptionType.badResponse) {
      log("Bad response: ${e.message}");
    } else if (e.type == DioExceptionType.cancel) {
      log("Request to API server was cancelled.");
    } else if (e.type == DioExceptionType.unknown) {
      log("Unexpected error occurred: ${e.message}");
    } else {
      log("Unknown error: ${e.message}");
    }
  }

  Dio get dio => _dio;
}
