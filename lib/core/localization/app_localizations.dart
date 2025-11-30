// lib/core/localization/app_localizations.dart

class AppLocalizations {
  final bool isKorean;

  AppLocalizations(this.isKorean);

  // 메인/공통
  String get appTitle => isKorean ? '선문대 셔틀버스' : 'Sunmoon Shuttle';
  String get confirm => isKorean ? '확인' : 'Confirm';
  String get cancel => isKorean ? '취소' : 'Cancel';
  
  // 설정 화면
  String get settingsTitle => isKorean ? '설정' : 'Settings';
  String get language => isKorean ? '언어 설정' : 'Language';
  String get languageOption => isKorean ? '한국어' : 'English';
  String get account => isKorean ? '계정' : 'Account';
  String get logout => isKorean ? '로그아웃' : 'Logout';
  String get logoutConfirm => isKorean ? '정말 로그아웃 하시겠습니까?' : 'Are you sure you want to logout?';
  String get appInfo => isKorean ? '앱 정보' : 'App Info';
  String get version => isKorean ? '버전 정보' : 'Version';
  String get license => isKorean ? '오픈소스 라이선스' : 'Open Source License';
  
  // 탭바
  String get tabMain => isKorean ? '메인화면' : 'Home';
  String get tabLocation => isKorean ? '위치' : 'Location';
  String get tabShuttle => isKorean ? '셔틀시간표' : 'Bus Time';
  String get tabSchool => isKorean ? '학기시간표' : 'School Time';
  String get tabSettings => isKorean ? '설정' : 'Settings';
}