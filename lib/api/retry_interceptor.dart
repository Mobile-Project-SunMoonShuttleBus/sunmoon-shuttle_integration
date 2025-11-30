import 'package:dio/dio.dart';
// [수정] 2번 코드 구조에 맞춘 경로
import '../core/utils/app_logger.dart';

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    if (retryCount >= maxRetries) {
      AppLogger.warning('RetryInterceptor', '최대 재시도 횟수 초과');
      handler.next(err);
      return;
    }

    AppLogger.info('RetryInterceptor', '재시도 중... (${retryCount + 1}/$maxRetries)');
    await Future.delayed(retryDelay);

    try {
      final opts = err.requestOptions;
      opts.extra['retryCount'] = retryCount + 1;

      final dio = Dio(BaseOptions(
        baseUrl: opts.baseUrl,
        connectTimeout: opts.connectTimeout,
        receiveTimeout: opts.receiveTimeout,
        headers: opts.headers,
      ));
      
      final response = await dio.fetch(opts);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
         onError(e, handler); // 재귀 호출로 다시 체크
      } else {
        handler.next(err);
      }
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response != null && err.response!.statusCode! >= 500);
  }
}