// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'clients_screen.dart';
import 'app_settings_screen.dart';
import 'add_client_sheet.dart';
import '../utils/app_translations.dart';
import '../database_helper.dart';
import 'notifications_screen.dart';

const _kPrimary = Color(0xFF1B8A6B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _clientsScreenKey = GlobalKey<ClientsScreenState>();
  final _supplierScreenKey = GlobalKey<ClientsScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onClientSaved() {
    if (_tabController.index == 0) {
      _clientsScreenKey.currentState?.loadData();
    } else {
      _supplierScreenKey.currentState?.loadData();
    }
  }
Future<int> _countUpcomingCheques() async {
  try {
    final db  = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final in15 = now.add(const Duration(days: 15));
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM cheques
      WHERE statut = 'EN_ATTENTE'
      AND dateEcheance <= ?
    ''', [in15.toIso8601String()]);
    return (rows.first['cnt'] as int?) ?? 0;
  } catch (_) {
    return 0;
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.book_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Tr.s('app_title'),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          // ── زر الإشعارات مع Badge ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.push(
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
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
          // ── زر الإعدادات ──
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(text: Tr.s('clients')),
            Tab(text: Tr.s('suppliers')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClientsScreen(
            key: _clientsScreenKey,
            type: 'CLIENT',
            onStatsChanged: () => setState(() {}),
          ),
          ClientsScreen(
            key: _supplierScreenKey,
            type: 'SUPPLIER',
            onStatsChanged: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final type = _tabController.index == 0 ? 'CLIENT' : 'SUPPLIER';
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
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (_, __) => Text(
            _tabController.index == 0
                ? Tr.s('add_client')
                : Tr.s('add_supplier'),
            style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          ),
        ),
      ),
    );
  }
}
