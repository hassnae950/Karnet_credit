import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';
import 'models.dart';
import 'screens/home_screen.dart';
import 'services/app_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load app settings (theme, lang, auto-backup)
  await AppSettingsService.instance.load();

  // Add default categories on first run
  await _addDefaultCategories();

  runApp(const KarnetApp());
}

Future<void> _addDefaultCategories() async {
  final categories = await DatabaseHelper.instance.getAllCategories();
  if (categories.isEmpty) {
    await DatabaseHelper.instance.createCategory(Category(name: 'زبائن VIP',      type: 'CLIENT'));
    await DatabaseHelper.instance.createCategory(Category(name: 'زبائن عاديون',   type: 'CLIENT'));
    await DatabaseHelper.instance.createCategory(Category(name: 'زبائن جدد',      type: 'CLIENT'));
    await DatabaseHelper.instance.createCategory(Category(name: 'موردين رئيسيين', type: 'SUPPLIER'));
    await DatabaseHelper.instance.createCategory(Category(name: 'موردين ثانويين', type: 'SUPPLIER'));
  }
}

class KarnetApp extends StatefulWidget {
  const KarnetApp({super.key});

  @override
  State<KarnetApp> createState() => _KarnetAppState();
}

class _KarnetAppState extends State<KarnetApp> {
  final _settings = AppSettingsService.instance;

  @override
  void initState() {
    super.initState();
    // Rebuild when theme changes
    _settings.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karnet Credit',
      themeMode: _settings.flutterThemeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B8A6B),
          primary: const Color(0xFF1B8A6B),
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
        textTheme: GoogleFonts.cairoTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B8A6B),
          primary: const Color(0xFF1B8A6B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ── Splash Screen with Logo ──
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B8A6B),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo — tries asset first, fallback to icon
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'كارنيه',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تسيير الكريديات بسهولة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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