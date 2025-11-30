import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// [수정] 2번 코드 구조에 맞춘 경로
import '../core/utils/app_logger.dart';
import '../widgets/error_view.dart'; // 아래 4번에서 만들 파일

class ErrorInterceptor extends Interceptor {
  final BuildContext? context;

  ErrorInterceptor({this.context});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    // 500번대 서버 에러 처리
    if (statusCode != null && statusCode >= 500) {
      AppLogger.error('ErrorInterceptor', '서버 오류 ($statusCode): ${err.requestOptions.path}');
      _showErrorDialog(
        title: '서버 오류',
        message: '일시적인 서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      );
    }

    // 403 권한 없음
    if (statusCode == 403) {
      _showSnackBar('접근 권한이 없습니다.');
    }

    handler.next(err);
  }

  void _showSnackBar(String message) {
    if (context == null) return;
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showErrorDialog({String? title, String? message}) {
    if (context == null) return;
    
    // ErrorView를 사용하여 다이얼로그 표시
    ErrorView.show(
      context!,
      title: title,
      message: message,
    );
  }
}