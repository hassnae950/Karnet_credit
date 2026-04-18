import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _pinKey   = 'karnet_pin';
  static const _isSetKey = 'karnet_pin_set';

  Future<bool> isPinSet() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_isSetKey) ?? false;
  }

  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_pinKey, pin);
    await p.setBool(_isSetKey, true);
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_pinKey) == pin;
  }

  Future<void> resetPin() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pinKey);
    await p.remove(_isSetKey);
  }
}