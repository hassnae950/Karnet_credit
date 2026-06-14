// lib/screens/pin_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed     = Color(0xFFD32F2F);

/// شاشة إدخال PIN — تظهر فقط إذا كان PIN مفعّل في الإعدادات
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  static const _pinKey = 'karnet_pin';

  String _input = '';
  bool   _error = false;

  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_input.length >= 4) return;
    setState(() {
      _input += digit;
      _error  = false;
    });
    if (_input.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _validate);
    }
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = false;
    });
  }

  Future<void> _validate() async {
    final prefs    = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey) ?? '';

    if (_input == savedPin) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } else {
      _shakeCtrl.forward(from: 0);
      setState(() {
        _input = '';
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12121A) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),

            // ── Logo ──────────────────────────────────────────────────────────
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_outline, color: _kPrimary, size: 38),
            ),
            const SizedBox(height: 20),

            Text('أدخل الرمز السري',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('كارنيه',
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: Colors.grey.shade500)),

            const SizedBox(height: 48),

            // ── دوائر PIN ─────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  _shakeCtrl.isAnimating
                      ? (_shakeCtrl.value < 0.5 ? 10 : -10)
                      : 0,
                  0,
                ),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _input.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? _kRed
                          : filled ? _kPrimary : Colors.transparent,
                      border: Border.all(
                        color: _error
                            ? _kRed
                            : filled ? _kPrimary : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── رسالة الخطأ ───────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _error ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text('رمز خاطئ، حاول مجدداً',
                    style: TextStyle(
                        color: _kRed, fontFamily: 'Cairo', fontSize: 13)),
              ),
            ),

            const Spacer(),

            // ── لوحة الأرقام ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  _row(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _row(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _row(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80),
                      _digitBtn('0'),
                      _actionBtn(Icons.backspace_outlined, _onDelete),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map(_digitBtn).toList(),
      );

  Widget _digitBtn(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(digit,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 80, height: 80,
          child: Icon(icon, color: _kPrimary, size: 28),
        ),
      );
}