import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _currentUserKey = 'current_user';
  static const _usersDBKey = 'users_database';
  static const _isLoggedInKey = 'is_logged_in';
  static const _verificationCodeKey = 'verification_code';
  static const _verificationPhoneKey = 'verification_phone';

  /// تحقق ما إذا كان المستخدم مسجل دخول
  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_isLoggedInKey) ?? false;
  }

  /// الحصول على بيانات المستخدم الحالي
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

  /// ─────────────────────────────────────────────────────────────
  /// النمط المبسط: رقم هاتف + OTP + Username (بدون Password)
  /// ─────────────────────────────────────────────────────────────

  /// 1️⃣ طلب كود التحقق للهاتف
  Future<bool> requestPhoneVerification(String phone) async {
    if (phone.isEmpty) return false;

    // توليد كود عشوائي (6 أرقام)
    final code = _generateOTP();

    final p = await SharedPreferences.getInstance();
    await p.setString(_verificationPhoneKey, phone);
    await p.setString(_verificationCodeKey, code);

    // في الواقع: هنا يُرسل عبر WhatsApp API أو SMS
    print('🔐 Verification Code for $phone: $code'); // للـ testing
    
    return true;
  }

  /// 2️⃣ التحقق من الكود
  Future<bool> verifyPhoneCode(String code) async {
    final p = await SharedPreferences.getInstance();
    
    final storedCode = p.getString(_verificationCodeKey);
    final phone = p.getString(_verificationPhoneKey);

    if (storedCode == null || phone == null) return false;
    if (storedCode != code) return false;

    // الكود صحيح - حفظ الهاتف مؤقتاً للخطوة التالية
    // (لا نسجل الدخول حالياً - ننتظر اسم المستخدم)

    return true;
  }

  /// 3️⃣ إكمال التسجيل بـ Username (بدون password)
  Future<bool> completeRegistration(String username) async {
    if (username.isEmpty) return false;

    final p = await SharedPreferences.getInstance();
    final phone = p.getString(_verificationPhoneKey);

    if (phone == null) return false;

    // التحقق من عدم تكرار username
    final users = _getUsersDatabase(p);
    final exists = users.any((u) => u['username'] == username);
    if (exists) return false;

    // إنشاء مستخدم جديد
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'username': username,
      'phone': phone,
      'dateCreation': DateTime.now().toIso8601String(),
    };

    users.add(newUser);
    await p.setString(_usersDBKey, jsonEncode(users));
    await p.setString(_currentUserKey, jsonEncode(newUser));
    await p.setBool(_isLoggedInKey, true);

    // تنظيف البيانات المؤقتة
    await p.remove(_verificationCodeKey);
    await p.remove(_verificationPhoneKey);

    return true;
  }

  /// 4️⃣ دخول سريع - رقم هاتف فقط
  Future<bool> quickLogin(String phone) async {
    if (phone.isEmpty) return false;

    final p = await SharedPreferences.getInstance();
    final users = _getUsersDatabase(p);

    // البحث عن مستخدم بنفس الهاتف
    final existingUser = users.firstWhere(
      (u) => u['phone'] == phone,
      orElse: () => {},
    );

    if (existingUser.isEmpty) return false;

    // دخول المستخدم الموجود
    await p.setString(_currentUserKey, jsonEncode(existingUser));
    await p.setBool(_isLoggedInKey, true);

    return true;
  }

  /// ─────────────────────────────────────────────────────────────
  /// تسجيل الخروج (اختياري - قد لا نستخدمه)
  /// ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_currentUserKey);
    await p.setBool(_isLoggedInKey, false);
  }

  /// ─────────────────────────────────────────────────────────────
  /// Helpers
  /// ─────────────────────────────────────────────────────────────

  /// توليد كود تحقق عشوائي (6 أرقام)
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// الحصول على قاعدة بيانات المستخدمين
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