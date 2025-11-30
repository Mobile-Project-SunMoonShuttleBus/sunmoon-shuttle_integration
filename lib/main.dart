// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; 
import 'package:provider/provider.dart';

// 1번 코드의 핵심 인프라
import 'api/dio_client.dart'; 
import 'cache/cache_manager.dart';
import 'provider/auth_provider.dart'; // 👈 Provider 경로
import 'provider/login_provider.dart'; // 👈 Provider 경로
import 'provider/settings_provider.dart'; // [추가]

// 2번 코드의 UI
import 'screen/main_screen.dart'; // 👈 screens/ (복수)로 경로 수정
import 'storage/login_screen.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 캐시 정리 및 DioClient 초기화
  await CacheManager.I.init();
  DioClient.instance; 

  // 2. [수정됨] 네이버 지도 SDK 초기화 (작동하는 최신 문법으로 수정)
  await FlutterNaverMap().init(
    clientId: 'i94jktzz8g', // 사용자 요청 ID
    onAuthFailed: (ex) {
      print("********* 네이버맵 인증 오류 발생: $ex *********");
    }
  );
  
  runApp(
    MultiProvider(
      providers: [
        // ✅ 최상위 AuthProvider 설정
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // LoginProvider는 여기서 제공하거나 LoginScreen 내부에서 제공 (여기서는 내부 제공 유지)

        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // DioClient에 Context 설정 및 자동 로그인 시도
      DioClient.instance.setRootContext(context);
      context.read<AuthProvider>().tryAutoLogin(); 
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '선문대 셔틀버스',
      theme: ThemeData(primarySwatch: Colors.blue),
      
      // ✅ AuthProvider 상태에 따라 화면 자동 전환 (로그인 화면 VS 메인 화면)
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (authProvider.isAuthenticated) {
            return  MainScreen(); // 로그인 성공
          } else {
            return LoginScreen(); // 로그인 필요 (LoginScreen으로 이동)
          }
        },
      ),
    );
  }
}