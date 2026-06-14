// lib/screens/verification_and_username_screen.dart
// UltraMsg WhatsApp OTP + Username

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/app_translations.dart';
import 'home_screen.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed     = Color(0xFFD32F2F);

class VerificationAndUsernameScreen extends StatefulWidget {
  final String phone;
  final SyncService syncService;

  const VerificationAndUsernameScreen({
    super.key,
    required this.phone,
    required this.syncService,
  });

  @override
  State<VerificationAndUsernameScreen> createState() =>
      _VerificationAndUsernameScreenState();
}

class _VerificationAndUsernameScreenState
    extends State<VerificationAndUsernameScreen> {

  final _codeCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _isVerifyingCode   = false;
  bool _isLoggingIn       = false;
  bool _showUsernameField = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. التحقق من كود WhatsApp
  // ═══════════════════════════════════════════════════════════════

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'الكود يجب أن يكون 6 أرقام');
      return;
    }

    setState(() { _isVerifyingCode = true; _error = null; });

    try {
      final success = await AuthService.instance.verifyPhoneCode(code);
      if (success && mounted) {
        setState(() => _showUsernameField = true);
      } else if (mounted) {
        setState(() => _error = 'كود غير صحيح أو منتهي الصلاحية');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'خطأ في التحقق: $e');
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. تسجيل الدخول + Restore
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loginAndRestore() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'اسم المستخدم مطلوب');
      return;
    }

    setState(() { _isLoggingIn = true; _error = null; });

    try {
      final loginSuccess =
          await AuthService.instance.completeRegistration(username);

      if (!loginSuccess || !mounted) {
        setState(() => _error = 'فشل تسجيل الدخول، جرب مرة أخرى');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', widget.phone);
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      _showRestoreDialog();

      final hasInternet = await widget.syncService.hasInternetConnection();
      bool restored = false;
      if (hasInternet) {
        final phone = prefs.getString('user_phone') ?? widget.phone;
        restored = await widget.syncService.restoreAllData(phone);
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (restored &&
          widget.syncService.syncStatus == Tr.s('restore_success')) {
        _showSnack('تم استعادة البيانات بنجاح', isSuccess: true);
      }

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        setState(() => _error = 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  UI Helpers
  // ═══════════════════════════════════════════════════════════════

  void _showRestoreDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('جاري تحميل البيانات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Row(children: [
          CircularProgressIndicator(color: _kPrimary),
          SizedBox(width: 16),
          Expanded(
            child: Text('يرجى الانتظار...',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ]),
      ),
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isSuccess ? _kPrimary : Colors.orange,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12121A) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ──────────────────────────────────────────────
              Text(
                _showUsernameField ? 'اسم المستخدم' : 'التحقق من الهاتف',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),

              // ── WhatsApp badge ───────────────────────────────────────
              if (!_showUsernameField)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'تم إرسال الكود عبر WhatsApp إلى ${widget.phone}',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: Color(0xFF25D366)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ── Code Field ───────────────────────────────────────────
              if (!_showUsernameField)
                TextField(
                  controller: _codeCtrl,
                  enabled: !_isVerifyingCode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        letterSpacing: 10,
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                  ),
                ),

              // ── Username Field ───────────────────────────────────────
              if (_showUsernameField)
                TextField(
                  controller: _usernameCtrl,
                  enabled: !_isLoggingIn,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'أدخل اسمك أو اسم محلك',
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: const Icon(Icons.person_outlined,
                        color: _kPrimary),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                  ),
                ),

              // ── Error ────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: _kRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: _kRed,
                              fontSize: 13,
                              fontFamily: 'Cairo')),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // ── Verify Button ────────────────────────────────────────
              if (!_showUsernameField)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isVerifyingCode ? null : _verifyCode,
                    child: _isVerifyingCode
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('التحقق',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo')),
                  ),
                ),

              // ── Login Button ─────────────────────────────────────────
              if (_showUsernameField)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoggingIn ? null : _loginAndRestore,
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('الدخول',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo')),
                  ),
                ),

              if (!_showUsernameField) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'لم تستقبل الكود؟ تحقق من WhatsApp',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey.shade600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}