import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF1B8A6B);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageCtrl;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'مرحباً بك في كارنيه',
      description: 'تطبيق ذكي لتسيير الكريديات والديون\nبسهولة وأمان',
      icon: Icons.book_outlined,
    ),
    OnboardingPage(
      title: 'إدارة سهلة',
      description: 'تابع جميع ديون وكريديات عملائك\nفي مكان واحد',
      icon: Icons.people_outline,
    ),
    OnboardingPage(
      title: 'تذكيرات ذكية',
      description: 'احصل على تذكيرات تلقائية\nقبل مواعيد الاستحقاق',
      icon: Icons.notifications,
    ),
    OnboardingPage(
      title: 'آمان محمي',
      description: 'كل بياناتك محمية برقم هاتفك\nوكود تحقق آمن',
      icon: Icons.lock_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: isDark ? const Color(0xFF12121A) : const Color(0xFFF5F6FA),
    body: SafeArea(
      child: Column(
        children: [
          // ── Skip Button ──────────────────────────────────────────
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    color: Color(0xFF1B8A6B),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // ── Pages ───────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) =>
                  _buildPage(_pages[index], isDark),
              itemCount: _pages.length,
            ),
          ),

          // ── Indicators ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  width: _currentPage == index ? 32 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF1B8A6B)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // ── Navigation Buttons ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Button
                _currentPage > 0
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF1B8A6B), width: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _pageCtrl.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text(
                          'السابق',
                          style: TextStyle(
                            color: Color(0xFF1B8A6B),
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox(width: 100),

                // Next Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A6B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'ابدأ' : 'التالي',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPage(OnboardingPage page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon ──────────────────────────────────────────────────
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              page.icon,
              color: _kPrimary,
              size: 56,
            ),
          ),

          const SizedBox(height: 40),

          // ── Title ─────────────────────────────────────────────────
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          // ── Description ──────────────────────────────────────────
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Cairo',
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
