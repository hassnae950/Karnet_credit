// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';
import 'utils/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.instance.load();
  Tr.setLang(AppSettingsService.instance.lang);
  runApp(const KarnetApp());
}

class KarnetApp extends StatefulWidget {
  const KarnetApp({super.key});

  @override
  State<KarnetApp> createState() => _KarnetAppState();
}

class _KarnetAppState extends State<KarnetApp> {
  final _svc = AppSettingsService.instance;
  final _authService = AuthService.instance;

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
    setState(() {});
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
      // ── Home Route ──────────────────────────────────────────────
      home: FutureBuilder<bool>(
        future: _authService.isLoggedIn(),
        builder: (context, snapshot) {
          // بينما نتحقق
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // بعد التحقق
          final isLoggedIn = snapshot.data ?? false;

          // إذا مسجل دخول → HomeScreen
          // وإلا → OnboardingScreen (أول مرة) أو LoginScreen
          if (isLoggedIn) {
            return const HomeScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      ),

      // ── Named Routes ────────────────────────────────────────────
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
  }
}

// ── Splash Screen ────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B8A6B),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.book_outlined,
                        color: Colors.white, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'كارنيه',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تسيير الكريديات بسهولة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}