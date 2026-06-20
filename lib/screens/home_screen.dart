// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'clients_screen.dart';
import 'app_settings_screen.dart';
import 'add_client_sheet.dart';
import '../utils/app_translations.dart';
import '../database_helper.dart';
import 'notifications_screen.dart';

const _kBlue = Color(0xFF1976D2);
const _kBlueDark = Color(0xFF1565C0);
const _kBlueLight = Color(0xFFE3F2FD);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // 0 = ديون, 1 = نقدية, 2 = مزيد

  final _clientsScreenKey = GlobalKey<ClientsScreenState>();
  final _supplierScreenKey = GlobalKey<ClientsScreenState>();

  // 0 = clients, 1 = suppliers داخل tab الديون
  int _debtTab = 0;

  double _totalAkhadt = 0;
  double _totalA3tit = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT
          SUM(CASE WHEN type = 'CREDIT' THEN amount ELSE 0 END) as credit_total,
          SUM(CASE WHEN type = 'PAIEMENT' THEN amount ELSE 0 END) as paiement_total
        FROM (
          SELECT 'CREDIT' as type, montant as amount FROM credits
          UNION ALL
          SELECT 'PAIEMENT' as type, montant as amount FROM paiements
        )
      ''');
      if (mounted) {
        setState(() {
          _totalAkhadt = (rows.first['credit_total'] as num?)?.toDouble() ?? 0;
          _totalA3tit =
              (rows.first['paiement_total'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<int> _countUpcomingCheques() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final in15 = DateTime.now().add(const Duration(days: 15));
      final rows = await db.rawQuery('''
        SELECT COUNT(*) as cnt FROM cheques
        WHERE statut = 'EN_ATTENTE' AND dateEcheance <= ?
      ''', [in15.toIso8601String()]);
      return (rows.first['cnt'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void _onClientSaved() {
    _loadStats();
    if (_debtTab == 0) {
      _clientsScreenKey.currentState?.loadData();
    } else {
      _supplierScreenKey.currentState?.loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDebtScreen(theme, isDark),
          _buildCashScreen(theme, isDark),
          _buildMoreScreen(theme, isDark),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                final type = _debtTab == 0 ? 'CLIENT' : 'SUPPLIER';
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddClientSheet(
                    onSaved: _onClientSaved,
                    defaultType: type,
                  ),
                );
              },
              backgroundColor: _kBlue,
              icon: const Icon(Icons.person_add_outlined, color: Colors.white),
              label: Text(
                _debtTab == 0 ? Tr.s('add_client') : Tr.s('add_supplier'),
                style:
                    const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ── شاشة الديون الرئيسية ─────────────────────────────────────────────────
  Widget _buildDebtScreen(ThemeData theme, bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(isDark),

          // ── Tab selector (العملاء / الموردين) ──
          _buildDebtTabSelector(isDark),

          // ── Stats card ──
          _buildStatsCard(isDark),

          // ── Search + PDF row ──
          Expanded(
            child: _debtTab == 0
                ? ClientsScreen(
                    key: _clientsScreenKey,
                    type: 'CLIENT',
                    onStatsChanged: () {
                      setState(() {});
                      _loadStats();
                    },
                  )
                : ClientsScreen(
                    key: _supplierScreenKey,
                    type: 'SUPPLIER',
                    onStatsChanged: () {
                      setState(() {});
                      _loadStats();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // ── أيقونة التطبيق ──
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.menu_book_rounded,
                  color: _kBlue,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            Tr.s('app_title'),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          // ── زر الإشعارات ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              _headerIconBtn(
                icon: Icons.notifications_outlined,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              FutureBuilder<int>(
                future: _countUpcomingCheques(),
                builder: (_, snap) {
                  final count = snap.data ?? 0;
                  if (count == 0) return const SizedBox();
                  return Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(
      {required IconData icon,
      required bool isDark,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon,
            color: isDark ? Colors.white70 : const Color(0xFF1A1A2E), size: 22),
      ),
    );
  }

  Widget _buildDebtTabSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            _debtTabBtn(
                index: 0,
                label: Tr.s('clients'),
                icon: Icons.person_outline,
                isDark: isDark),
            _debtTabBtn(
                index: 1,
                label: Tr.s('suppliers'),
                icon: Icons.local_shipping_outlined,
                isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _debtTabBtn(
      {required int index,
      required String label,
      required IconData icon,
      required bool isDark}) {
    final selected = _debtTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _debtTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _kBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? Colors.white
                      : isDark
                          ? Colors.white54
                          : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : isDark
                          ? Colors.white54
                          : Colors.grey,
                  fontFamily: 'Cairo',
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            // ── أخذت ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('أخذت',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontFamily: 'Cairo',
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${_totalAkhadt.toStringAsFixed(1)} درهم',
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            // ── divider ──
            Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16)),
            // ── أعطيت ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أعطيت',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontFamily: 'Cairo',
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${_totalA3tit.toStringAsFixed(1)} درهم',
                    style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            // ── أزرار ──
            Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16)),
            Row(
              children: [
                _statsIconBtn(
                    icon: Icons.bar_chart_rounded,
                    label: 'التقارير',
                    onTap: () {}),
                const SizedBox(width: 12),
                _statsIconBtn(
                    icon: Icons.alarm_rounded,
                    label: 'تحصيل الديون',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsIconBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kBlue, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 10, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  // ── شاشة النقدية (placeholder) ──────────────────────────────────────────
  Widget _buildCashScreen(ThemeData theme, bool isDark) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('دفتر النقدية',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('قريباً...',
                style: TextStyle(
                    fontFamily: 'Cairo', color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  // ── شاشة المزيد ─────────────────────────────────────────────────────────
  Widget _buildMoreScreen(ThemeData theme, bool isDark) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text('المزيد',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          _moreItem(
            icon: Icons.settings_outlined,
            label: 'الإعدادات',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ).then((_) => setState(() {})),
          ),
          _moreItem(
            icon: Icons.notifications_outlined,
            label: 'الإشعارات',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreItem(
      {required IconData icon,
      required String label,
      required bool isDark,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kBlueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation ────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                  index: 0,
                  icon: Icons.menu_book_rounded,
                  label: 'دفتر الديون',
                  isDark: isDark),
              _navItem(
                  index: 1,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'دفتر النقدية',
                  isDark: isDark),
              _navItem(
                  index: 2,
                  icon: Icons.grid_view_rounded,
                  label: 'المزيد',
                  isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      {required int index,
      required IconData icon,
      required String label,
      required bool isDark}) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kBlue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? _kBlue
                    : isDark
                        ? Colors.white38
                        : Colors.grey,
                size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? _kBlue
                    : isDark
                        ? Colors.white38
                        : Colors.grey,
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}