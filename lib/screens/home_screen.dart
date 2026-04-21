import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'clients_screen.dart';
import 'app_settings_screen.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> _statsClient = {'totalCredit': 0, 'totalRestant': 0, 'totalPaye': 0};
  Map<String, double> _statsSupplier = {'totalCredit': 0, 'totalRestant': 0, 'totalPaye': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final clientStats = await DatabaseHelper.instance.getStatsByType('CLIENT');
      final supplierStats = await DatabaseHelper.instance.getStatsByType('SUPPLIER');

      setState(() {
        _statsClient = clientStats;
        _statsSupplier = supplierStats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B8A6B),
        title: const Text(
          'كارنيه',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ).then((_) => _loadStats()),
          ),
        ],
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: const Color(0xFF1B8A6B),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Text
                    Text(
                      'مرحبا بك في كارنيه',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تسيير الكريديات بسهولة',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Clients Card
                    _buildStatCard(
                      context,
                      title: 'الزبائن',
                      total: _statsClient['totalCredit']!,
                      restant: _statsClient['totalRestant']!,
                      paye: _statsClient['totalPaye']!,
                      color: Colors.red,
                      onTap: () => _openClientsScreen('CLIENT'),
                    ),

                    const SizedBox(height: 16),

                    // Suppliers Card
                    _buildStatCard(
                      context,
                      title: 'الموردين',
                      total: _statsSupplier['totalCredit']!,
                      restant: _statsSupplier['totalRestant']!,
                      paye: _statsSupplier['totalPaye']!,
                      color: Colors.orange,
                      onTap: () => _openClientsScreen('SUPPLIER'),
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions
                    Text(
                      'إجراءات سريعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _quickActionButton(
                            icon: Icons.person_add,
                            label: 'إضافة زبون',
                            color: Colors.green,
                            onTap: () => _openClientsScreen('CLIENT'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickActionButton(
                            icon: Icons.local_shipping,
                            label: 'إضافة مورد',
                            color: Colors.blue,
                            onTap: () => _openClientsScreen('SUPPLIER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double total,
    required double restant,
    required double paye,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statItem('المجموع', total, color),
                const Spacer(),
                _statItem('الباقي', restant, Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? (paye / total).clamp(0.0, 1.0) : 0,
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${total > 0 ? ((paye / total) * 100).toStringAsFixed(0) : 0}% مدفوع',
              style: TextStyle(
                color: color,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatMontant(amount),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openClientsScreen(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientsScreen(type: type),
      ),
    ).then((_) => _loadStats());
  }
}