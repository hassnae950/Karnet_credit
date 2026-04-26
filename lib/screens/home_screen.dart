import 'package:flutter/material.dart';
import 'clients_screen.dart';
import 'app_settings_screen.dart';
import 'add_client_sheet.dart';
import '../utils/app_translations.dart';

const _kPrimary = Color(0xFF1B8A6B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ).then((_) => setState(() {})), // refresh lang
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
            type: 'CLIENT',
            onStatsChanged: () => setState(() {}),
          ),
          ClientsScreen(
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
              onSaved: () => setState(() {}),
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