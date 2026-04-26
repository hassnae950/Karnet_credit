import 'package:flutter/material.dart';
import '../services/auth_service.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kGreen   = Color(0xFF388E3C);

class VerificationAndUsernameScreen extends StatefulWidget {
  final String phone;

  const VerificationAndUsernameScreen({
    super.key,
    required this.phone,
  });

  @override
  State<VerificationAndUsernameScreen> createState() =>
      _VerificationAndUsernameScreenState();
}

class _VerificationAndUsernameScreenState
    extends State<VerificationAndUsernameScreen> {
  final _codeCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _authService = AuthService.instance;

  bool _loading = false;
  bool _codeVerified = false;
  String? _error;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();

    if (code.isEmpty || code.length != 6) {
      setState(() => _error = 'أدخل كود صحيح (6 أرقام)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await _authService.verifyPhoneCode(code);

      if (success && mounted) {
        setState(() {
          _codeVerified = true;
          _loading = false;
          _error = null;
        });
      } else if (mounted) {
        setState(() => _error = 'الكود غير صحيح');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeRegistration() async {
    final username = _usernameCtrl.text.trim();

    if (username.isEmpty) {
      setState(() => _error = 'اسم المستخدم مطلوب');
      return;
    }

    if (username.length < 3) {
      setState(() => _error = 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await _authService.completeRegistration(username);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'مرحباً بك في كارنيه!',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: _kGreen,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        setState(() => _error = 'هذا الاسم مستخدم بالفعل');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resendCode() {
    setState(() => _resendCountdown = 60);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        if (_resendCountdown > 0) _resendCode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12121A) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final fillColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        elevation: 0,
        title: const Text(
          'إكمال التسجيل',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Step 1: Verification Code ─────────────────────────────────
              if (!_codeVerified) ...[
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: _kPrimary, size: 48),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'تحقق من الكود',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'أدخل الكود الذي أرسلناه إلى\n${widget.phone}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 40),

                // OTP Input
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: const TextStyle(fontSize: 32, letterSpacing: 8),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kPrimary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kPrimary, width: 2),
                    ),
                    counterText: '',
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFD32F2F), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _verifyCode,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'تحقق',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend Code
                GestureDetector(
                  onTap: _resendCountdown > 0 ? null : _resendCode,
                  child: Text(
                    _resendCountdown > 0
                        ? 'أعد الإرسال بعد $_resendCountdown ثانية'
                        : 'لم تستقبل الكود؟ أعد الإرسال',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: _resendCountdown > 0
                          ? Colors.grey
                          : _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]

              // ── Step 2: Username ───────────────────────────────────────
              else ...[
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_outlined,
                      color: _kGreen, size: 48),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'اختر اسم المستخدم',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'هذا الاسم سيظهر لعملائك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 40),

                // Username Field
                TextField(
                  controller: _usernameCtrl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'مثال: أحمد البقال',
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: const Icon(Icons.person_outline,
                        color: _kPrimary),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFD32F2F), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 20),

                // Complete Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _completeRegistration,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ابدأ الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}