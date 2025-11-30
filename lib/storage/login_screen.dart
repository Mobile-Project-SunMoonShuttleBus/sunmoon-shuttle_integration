// lib/storage/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1번 코드의 인증 모듈들
import '../provider/auth_provider.dart';
import '../provider/login_provider.dart'; 
import '../core/utils/validators.dart';
import '../storage/register_screen.dart'; 


class LoginScreen extends StatefulWidget { // 🛑 [수정] StatelessWidget -> StatefulWidget
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> { // 🛑 [추가] State 클래스
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ⭐️ [핵심 수정] TextField에 리스너를 붙여서, 텍스트가 바뀔 때마다 UI를 업데이트합니다.
    _idController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 텍스트 변경 시 호출되어 UI를 리빌드하는 함수
  void _onTextChanged() {
    // setState를 호출하여 버튼의 disabled 상태를 다시 평가하도록 합니다.
    setState(() {}); 
  }
  
  // 로그인 버튼 클릭 시 처리
  Future<void> _login(BuildContext context, LoginProvider loginProvider) async {
    // 폼이 유효하지 않으면 API 호출하지 않음
    if (!_isFormValid()) return;
    
    final success = await loginProvider.login(
      userId: _idController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      if (context.mounted) {
        context.read<AuthProvider>().setAuthenticated(true);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginProvider.errorMessage ?? '로그인 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 회원가입 화면으로 이동하는 함수
  void _goToRegister(BuildContext context) {
     Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RegisterScreen()),
     );
  }

  // [추가] 폼 유효성 검사 함수 (Validators 기반)
  bool _isFormValid() {
    final id = _idController.text.trim();
    final pw = _passwordController.text;
    // Validators.dart의 규칙을 사용합니다.
    if (!Validators.isValidUserId(id)) return false; 
    if (!Validators.isValidPassword(pw)) return false; 
    return true;
  }

  // --- UI 헬퍼 함수 (1번 코드 스타일) ---
  
  // 라벨이 있는 입력 필드 위젯
  Widget _labeledInput(
    TextEditingController c,
    String label, {
    bool obscure = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        Expanded(
          child: TextField(
            controller: c,
            obscureText: obscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white, 
              border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF1890FF), width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // 메인 액션 버튼 (파란색 배경)
  Widget _primaryButton({required String text, required VoidCallback onPressed, bool disabled = false}) {
    return SizedBox(
      width: double.infinity, 
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey[300] : const Color(0xFF1890FF),
          foregroundColor: disabled ? Colors.black54 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(text),
      ),
    );
  }

  // 보조 액션 버튼 (회색 배경)
  Widget _grayButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: const Color(0xFF1890FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(text),
      ),
    );
  }

  // --- UI 빌드 ---
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1890FF),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Consumer<LoginProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('로그인', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1890FF))),
                        const SizedBox(height: 32),

                        _labeledInput(_idController, '아이디'),
                        const SizedBox(height: 16),
                        _labeledInput(_passwordController, '비밀번호', obscure: true),
                        
                        // 에러 메시지
                        if (provider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // 로그인 버튼 (Primary)
                        _primaryButton(
                          text: provider.isLoading ? '처리 중...' : '로그인',
                          disabled: !_isFormValid() || provider.isLoading, // 🛑 [수정] _isFormValid() 사용
                          onPressed: () => _login(context, provider),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 회원가입 버튼 (Gray Button)
                        _grayButton(
                          text: '회원가입',
                          onPressed: () => _goToRegister(context),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}