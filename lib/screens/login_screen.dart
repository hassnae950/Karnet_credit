// lib/screens/login_screen.dart
// Firebase Phone Auth

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'verification_and_username_screen.dart';

const _kPrimary = Color(0xFF1B8A6B);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOTP() async {
    final phone = _phoneCtrl.text.trim();

    if (phone.isEmpty) {
      setState(() => _error = 'رقم الهاتف مطلوب');
      return;
    }
    if (!RegExp(r'^[0-9+\-\s]+$').hasMatch(phone)) {
      setState(() => _error = 'رقم الهاتف غير صحيح');
      return;
    }

    setState(() { _loading = true; _error = null; });

    await AuthService.instance.requestPhoneVerification(
      phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationAndUsernameScreen(
              phone: phone,
              syncService: SyncService.instance,
            ),
          ),
        );
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() { _loading = false; _error = msg; });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12121A) : const Color(0xFFF5F6FA);
    final cardBg  = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ── Logo ──────────────────────────────────────────────────
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.book_outlined, color: _kPrimary, size: 48),
              ),
              const SizedBox(height: 24),

              Text('كارنيه',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),

              Text('تسيير الكريديات بسهولة',
                  style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      color: Colors.grey.shade600)),
              const SizedBox(height: 80),

              // ── Card ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الدخول برقم الهاتف',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 8),
                    Text('سنرسل كود التحقق عبر SMS',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cairo',
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 24),

                    // ── Phone Field ──────────────────────────────────────
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: '+212 6 12 34 56 78',
                        hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        prefixIcon: const Icon(Icons.phone_outlined, color: _kPrimary),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                      ),
                    ),

                    // ── Error ────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFD32F2F), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 13,
                                    fontFamily: 'Cairo')),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Button ───────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loading ? null : _requestOTP,
                        child: _loading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('طلب كود التحقق',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}