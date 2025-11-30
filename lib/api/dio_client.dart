import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// [수정] 경로를 현재 구조에 맞게 변경
import '../core/utils/app_logger.dart'; 
import '../cache/cache_manager.dart';

// [수정] 같은 api 폴더 안에 있다고 가정하고 import
import 'cache_interceptor.dart';
import 'error_interceptor.dart';
import 'retry_interceptor.dart';
import 'dio_interceptor.dart'; // AuthInterceptor

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  
  // 인터셉터 인스턴스들
  final CacheInterceptor _cacheInterceptor = CacheInterceptor();
  final AuthInterceptor _authInterceptor = AuthInterceptor();
  final RetryInterceptor _retryInterceptor = RetryInterceptor();
  ErrorInterceptor? _errorInterceptor;

  DioClient._internal() {
    // 1. 서버 주소 설정 (기본값)
    const defaultBaseUrl = 'http://124.61.202.9:8080';
    
    // 환경변수 체크 (없으면 기본값)
    final envBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final baseUrl = envBaseUrl.isEmpty ? defaultBaseUrl : envBaseUrl;

    AppLogger.info('DioClient', 'API Base URL: $baseUrl');

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
    ));

    // 2. 인터셉터 추가 (순서 중요)
    // Cache -> Auth -> Retry
    _dio.interceptors.add(_cacheInterceptor);
    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(_retryInterceptor);
    
    // ErrorInterceptor는 context가 필요해서 setRootContext에서 추가함

    // 3. CacheManager 초기화 시작
    CacheManager.I.init().catchError((error) {
      AppLogger.error('DioClient', 'CacheManager 초기화 실패', error is Error ? error.stackTrace : null);
    });
  }

  /// 싱글톤 인스턴스 반환
  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  /// Dio 객체 직접 접근 필요 시
  Dio get dio => _dio;

  /// 루트 컨텍스트 설정 (로그인 만료 시 튕겨내기 & 에러 다이얼로그용)
  void setRootContext(BuildContext? context) {
    // AuthInterceptor에 context 전달
    _authInterceptor.setRootContext(context);
    
    // ErrorInterceptor 재설정
    _dio.interceptors.removeWhere((interceptor) => interceptor is ErrorInterceptor);
    
    if (context != null) {
      _errorInterceptor = ErrorInterceptor(context: context);
      _dio.interceptors.add(_errorInterceptor!);
    } else {
      _errorInterceptor = null;
    }
  }

  // --- [편의 메서드] ---

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}