import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // 싱글톤 패턴 (앱 전체에서 하나의 인스턴스만 사용)
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = FlutterSecureStorage();
  final _tokenKey = 'jwt_token'; // 토큰을 저장할 키 이름

  // 1. 토큰 저장
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // 2. 토큰 읽기 (API 호출 시 사용)
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 3. 토큰 삭제 (로그아웃 시 사용)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}