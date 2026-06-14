// lib/main.dart — v2.4 + Auto Backup
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'utils/app_translations.dart';

// ── للتست: 2 دقيقة — بعد ما تتأكد غيّرها لـ 24 ساعة ─────────────────────────
// const _backupInterval = Duration(minutes: 2);   // ← للتست
const _backupInterval = Duration(hours: 24);       // ← للإنتاج

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Settings ──────────────────────────────────────────────────────────
  try {
    await AppSettingsService.instance.load();
    Tr.setLang(AppSettingsService.instance.lang);
    debugPrint('✅ Settings loaded');
  } catch (e) {
    debugPrint('⚠️ Settings failed: $e');
  }

  // ── 2. Firebase ──────────────────────────────────────────────────────────
  for (int i = 0; i < 3; i++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized');
      break;
    } catch (e) {
      if (e.toString().contains('duplicate-app')) break;
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      debugPrint('⚠️ Firebase retry ${i + 1}: $e');
    }
  }

  // ── 3. Notifications + Auto Backup في الخلفية ────────────────────────────
  Future.microtask(() async {
    try {
      await NotificationService.instance.init();
      if (AppSettingsService.instance.notificationsOn) {
        await NotificationService.instance
            .rescheduleAllFromDb(Tr.s('currency'));
      }
      debugPrint('✅ Notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Notifications failed: $e');
    }

    // ── Auto Backup ─────────────────────────────────────────────────────────
    await _runAutoBackupIfNeeded();
  });

  runApp(const KarnetApp());
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AUTO BACKUP — كيشوف آخر backup، إذا فات الوقت يعمل واحد جديد
// ═══════════════════════════════════════════════════════════════════════════════
Future<void> _runAutoBackupIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // ── شيك: المستخدم مسجل دخول؟ ──────────────────────────────────────────
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) {
      debugPrint('ℹ️ Auto Backup: user not logged in, skip');
      return;
    }

    final phone = prefs.getString('user_phone') ?? '';
    if (phone.isEmpty) {
      debugPrint('ℹ️ Auto Backup: no phone, skip');
      return;
    }

    // ── شيك: امتى كان آخر backup؟ ──────────────────────────────────────────
    final lastBackupMs = prefs.getInt('last_auto_backup_ms') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: now - lastBackupMs);

    if (lastBackupMs > 0 && elapsed < _backupInterval) {
      final remaining = _backupInterval - elapsed;
      debugPrint(
          'ℹ️ Auto Backup: not needed yet (${remaining.inMinutes} min remaining)');
      return;
    }

    // ── شيك: عندو انترنت؟ ──────────────────────────────────────────────────
    final hasInternet = await SyncService.instance.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('ℹ️ Auto Backup: no internet, skip');
      return;
    }

    // ── دير الـ Backup ──────────────────────────────────────────────────────
    debugPrint('🔄 Auto Backup: starting for $phone...');
    final success = await SyncService.instance.backupAllData(phone);

    if (success) {
      await prefs.setInt('last_auto_backup_ms', now);
      debugPrint('✅ Auto Backup: done!');
    } else {
      debugPrint('⚠️ Auto Backup: failed — will retry next launch');
    }
  } catch (e) {
    debugPrint('⚠️ Auto Backup error (non-fatal): $e');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  APP
// ═══════════════════════════════════════════════════════════════════════════════
class KarnetApp extends StatefulWidget {
  const KarnetApp({super.key});
  @override
  State<KarnetApp> createState() => _KarnetAppState();
}

class _KarnetAppState extends State<KarnetApp> {
  final _svc = AppSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _svc.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    Tr.setLang(_svc.lang);
    if (mounted) setState(() {});
  }

  ThemeMode get _themeMode {
    switch (_svc.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeData _buildTheme(Brightness brightness) => ThemeData(
        colorSchemeSeed: const Color(0xFF1B8A6B),
        brightness: brightness,
        fontFamily: 'Cairo',
        cardColor: brightness == Brightness.dark
            ? const Color(0xFF1E1E2E)
            : Colors.white,
        scaffoldBackgroundColor: brightness == Brightness.dark
            ? const Color(0xFF12121A)
            : const Color(0xFFF5F6FA),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كارنيه',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      locale: Tr.locale,
      supportedLocales: const [
        Locale('ar', 'MA'),
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: Tr.textDirection,
        child: child!,
      ),
      home: const _StartupRouter(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/pin-lock': (_) => const PinLockScreen(),
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STARTUP ROUTER
// ═══════════════════════════════════════════════════════════════════════════════
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();
  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  late final Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveHome();
  }

  Future<Widget> _resolveHome() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));

      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      if (!seenOnboarding) {
        await prefs.setBool('seen_onboarding', true);
        return const OnboardingScreen();
      }

      final isLoggedIn = await AuthService.instance
          .isLoggedIn()
          .timeout(const Duration(seconds: 3));
      if (!isLoggedIn) return const LoginScreen();

      final pinEnabled = prefs.getBool('karnet_pin_enabled') ?? false;
      if (pinEnabled) return const PinLockScreen();

      return const HomeScreen();
    } catch (e) {
      debugPrint('⚠️ Startup routing error: $e');
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}

// ── Splash ───────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1B8A6B),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
