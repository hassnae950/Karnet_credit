// lib/services/auth_service.dart
// UltraMsg WhatsApp OTP — بدل Firebase SMS

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  // ── UltraMsg Config ──────────────────────────────────────────────────────────
  static const _ultraInstance = 'instance179286';
  static const _ultraToken    = 'hkglj0sxcrhwrd68';
  static const _ultraBaseUrl  = 'https://api.ultramsg.com';

  static const _currentUserKey = 'current_user';
  static const _usersDBKey     = 'users_database';
  static const _isLoggedInKey  = 'is_logged_in';
  static const _otpKey         = '_otp_temp';
  static const _otpPhoneKey    = '_otp_phone';
  static const _otpExpiryKey   = '_otp_expiry';

  // ─────────────────────────────────────────────────────────────
  // Session
  // ─────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_isLoggedInKey) ?? false;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    final userJson = p.getString(_currentUserKey);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson);
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. طلب OTP عبر WhatsApp
  // ─────────────────────────────────────────────────────────────

  Future<void> requestPhoneVerification(
    String phone, {
    required void Function() onCodeSent,
    required void Function(String error) onError,
  }) async {
    try {
      final formattedPhone = _formatPhone(phone);

      // توليد كود عشوائي 6 أرقام
      final otp = (100000 + Random().nextInt(900000)).toString();

      // رسالة WhatsApp
      final message =
          '🔐 *كارنيه — كود التحقق*\n\nكودك هو: *$otp*\n\nصالح لمدة 5 دقائق.\nلا تشاركه مع أحد.';

      final response = await http.post(
        Uri.parse('$_ultraBaseUrl/$_ultraInstance/messages/chat'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': _ultraToken,
          'to':    formattedPhone,
          'body':  message,
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['sent'] == 'true') {
        // حفظ الكود مؤقتاً في SharedPreferences
        final p = await SharedPreferences.getInstance();
        final expiry = DateTime.now()
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch;
        await p.setString(_otpKey, otp);
        await p.setString(_otpPhoneKey, formattedPhone);
        await p.setInt(_otpExpiryKey, expiry);

        onCodeSent();
      } else {
        final errorMsg = data['error'] ?? 'فشل إرسال الكود';
        onError('خطأ: $errorMsg');
      }
    } catch (e) {
      onError('تعذر الاتصال، تحقق من الانترنت');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. التحقق من الكود
  // ─────────────────────────────────────────────────────────────

  Future<bool> verifyPhoneCode(String code) async {
    final p = await SharedPreferences.getInstance();
    final savedOtp    = p.getString(_otpKey);
    final expiryMs    = p.getInt(_otpExpiryKey) ?? 0;
    final now         = DateTime.now().millisecondsSinceEpoch;

    // شيك انتهاء المدة
    if (now > expiryMs) return false;

    // مقارنة الكود
    return savedOtp == code.trim();
  }

  // ─────────────────────────────────────────────────────────────
  // 3. إكمال التسجيل بعد التحقق
  // ─────────────────────────────────────────────────────────────

  Future<bool> completeRegistration(String username) async {
    if (username.isEmpty) return false;

    final p     = await SharedPreferences.getInstance();
    final phone = p.getString(_otpPhoneKey) ?? '';
    if (phone.isEmpty) return false;

    final users = _getUsersDatabase(p);

    // مستخدم موجود — دخول مباشر
    final existing = users.where((u) => u['phone'] == phone).toList();
    if (existing.isNotEmpty) {
      final user = existing.first;
      await p.setString(_currentUserKey, jsonEncode(user));
      await p.setBool(_isLoggedInKey, true);
      await p.setString('user_phone', phone);
      _clearOtp(p);
      return true;
    }

    // مستخدم جديد
    String finalUsername = username;
    if (users.any((u) => u['username'] == finalUsername)) {
      final rand = Random().nextInt(99) + 1;
      finalUsername = '${username}_$rand';
    }

    final newUser = {
      'id':           DateTime.now().millisecondsSinceEpoch,
      'username':     finalUsername,
      'phone':        phone,
      'dateCreation': DateTime.now().toIso8601String(),
    };

    users.add(newUser);
    await p.setString(_usersDBKey, jsonEncode(users));
    await p.setString(_currentUserKey, jsonEncode(newUser));
    await p.setBool(_isLoggedInKey, true);
    await p.setString('user_phone', phone);
    _clearOtp(p);

    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // 4. دخول سريع مستخدم موجود
  // ─────────────────────────────────────────────────────────────

  Future<bool> quickLogin(String phone) async {
    if (phone.isEmpty) return false;
    final p             = await SharedPreferences.getInstance();
    final users         = _getUsersDatabase(p);
    final formattedPhone = _formatPhone(phone);

    final existingUser = users.firstWhere(
      (u) => u['phone'] == phone || u['phone'] == formattedPhone,
      orElse: () => {},
    );
    if (existingUser.isEmpty) return false;

    await p.setString(_currentUserKey, jsonEncode(existingUser));
    await p.setBool(_isLoggedInKey, true);
    await p.setString('user_phone', existingUser['phone'] ?? phone);
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // تسجيل الخروج
  // ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_currentUserKey);
    await p.remove('user_phone');
    await p.setBool(_isLoggedInKey, false);
    _clearOtp(p);
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  void _clearOtp(SharedPreferences p) {
    p.remove(_otpKey);
    p.remove(_otpPhoneKey);
    p.remove(_otpExpiryKey);
  }

  String _formatPhone(String phone) {
    String p = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (p.startsWith('0') && p.length == 10) return '+212${p.substring(1)}';
    if (!p.startsWith('+')) return '+$p';
    return p;
  }

  List<Map<String, dynamic>> _getUsersDatabase(SharedPreferences p) {
    final json = p.getString(_usersDBKey);
    if (json == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(json));
    } catch (e) {
      return [];
    }
  }
}