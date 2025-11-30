import 'package:dio/dio.dart';
// [수정] 2번 코드 구조에 맞춘 경로
import '../cache/cache_manager.dart';
import '../core/utils/app_logger.dart'; 

class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager = CacheManager.I;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // GET 요청만 캐시 처리
    if (options.method != 'GET') {
      handler.next(options);
      return;
    }

    // 캐시 키 생성 (URL 기반)
    final cacheKey = _getCacheKey(options);
    if (cacheKey == null) {
      handler.next(options);
      return;
    }

    // 캐시 확인
    try {
      final cachedData = await _cacheManager.getCache(cacheKey);
      if (cachedData != null) {
        AppLogger.debug('CacheInterceptor', '캐시 히트: ${options.path}');
        final response = Response(
          requestOptions: options,
          data: cachedData,
          statusCode: 200,
          headers: Headers.fromMap({'cache': ['hit']}),
        );
        handler.resolve(response);
        return;
      }
    } catch (error) {
      AppLogger.warning('CacheInterceptor', '캐시 조회 실패: $cacheKey');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // GET 요청만 캐시 저장
    if (response.requestOptions.method != 'GET') {
      handler.next(response);
      return;
    }

    final cacheKey = _getCacheKey(response.requestOptions);
    if (cacheKey == null) {
      handler.next(response);
      return;
    }

    // TTL 결정 (기본값 사용하거나 URL별로 다르게 설정 가능)
    final ttl = _getTTL(cacheKey) ?? const Duration(minutes: 5);

    // 캐시 저장 (비동기)
    _cacheManager.setCache(cacheKey, response.data, ttl).catchError((error) {
      AppLogger.error('CacheInterceptor', '캐시 저장 실패', error is Error ? error.stackTrace : null);
    });

    handler.next(response);
  }

  String? _getCacheKey(RequestOptions options) {
    final path = options.path;
    final queryParams = options.queryParameters;
    
    // 쿼리 파라미터가 있으면 키에 포함
    if (queryParams.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      final queryString = sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      return '$path?$queryString';
    }
    
    return path;
  }

  Duration? _getTTL(String cacheKey) {
    // URL별로 유효기간(TTL) 다르게 설정 가능
    if (cacheKey.contains('stops')) return const Duration(days: 1); // 정류장은 1일
    if (cacheKey.contains('timetable')) return const Duration(hours: 1); // 시간표는 1시간
    return null; // 나머지는 기본값(위에서 5분으로 설정함)
  }
}