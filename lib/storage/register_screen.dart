// lib/storage/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// [경로 확인 필수]
import '../provider/register_provider.dart'; // lib/providers/
import '../core/utils/validators.dart';       // lib/core/utils/

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 실시간 유효성 검사 리스너 설정
    _idCtrl.addListener(_onTextChanged);
    _pwCtrl.addListener(_onTextChanged);
    _pw2Ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  // 텍스트 변경 시 유효성 검사 실행
  void _onTextChanged() {
    // context.read는 build 밖에서 사용 가능
    final provider = context.read<RegisterProvider>();
    provider.validateUserId(_idCtrl.text.trim());
    provider.validatePassword(_pwCtrl.text);
    provider.validatePasswordConfirm(_pwCtrl.text, _pw2Ctrl.text);
    // UI 업데이트
    setState(() {}); 
  }

  // 폼 전체 유효성 검사 (버튼 활성화/비활성화용)
  bool _isFormValid() {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pw2 = _pw2Ctrl.text;
    
    if (id.isEmpty || pw.isEmpty || pw2.isEmpty) return false;
    if (!Validators.isValidUserId(id)) return false;
    if (!Validators.isValidPassword(pw)) return false;
    if (pw != pw2) return false;
    
    return true;
  }
  
  Future<void> _handleSubmit(BuildContext context, RegisterProvider provider) async {
    if (!_isFormValid()) return;

    final success = await provider.register(
      userId: _idCtrl.text.trim(),
      password: _pwCtrl.text,
      passwordConfirm: _pw2Ctrl.text,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입 성공! 로그인해주세요.'), backgroundColor: Colors.green));
      Navigator.of(context).pop(); 
    } else if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? '회원가입 실패'), backgroundColor: Colors.red));
    }
  }
  
  // --- UI 헬퍼 함수 (LoginScreen과 동일한 스타일) ---

  // 라벨이 있는 입력 필드 위젯
  Widget _labeledInput(
    TextEditingController c,
    String label, {
    bool obscure = false,
    String? errorText, // Provider의 에러 메시지 받기
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        Expanded(
          child: TextFormField(
            controller: c,
            obscureText: obscure,
            // onChanged는 initState에서 리스너로 처리
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white, 
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF1890FF), width: 1)),
              errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.red, width: 1)),
              focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.red, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              errorText: errorText, // 실시간 유효성 검사 결과를 표시
            ),
            validator: (value) => (value == null || value.isEmpty) ? '필수 입력 항목입니다.' : null,
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
      create: (_) => RegisterProvider(),
      builder: (context, child) {
        final provider = context.watch<RegisterProvider>();
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
                child: Form( 
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('회원가입', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1890FF))),
                      const SizedBox(height: 32),

                      _labeledInput(_idCtrl, '아이디', errorText: provider.userIdError), 
                      const SizedBox(height: 16),
                      _labeledInput(_pwCtrl, '비밀번호', obscure: true, errorText: provider.passwordError),
                      const SizedBox(height: 16),
                      _labeledInput(_pw2Ctrl, '비밀번호 확인', obscure: true, errorText: provider.passwordConfirmError),
                      
                      const SizedBox(height: 24),
                      
                      // 전역 에러 메시지
                      if (provider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      
                      // 회원가입 버튼
                      _primaryButton(
                        text: provider.isLoading ? '처리 중...' : '회원가입',
                        disabled: !_isFormValid() || provider.isLoading, 
                        onPressed: () => _handleSubmit(context, provider),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 취소 버튼
                      _grayButton(
                        text: '취소',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}