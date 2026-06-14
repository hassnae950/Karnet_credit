// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';
import 'client_detail_screen.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed     = Color(0xFFD32F2F);
const _kOrange  = Color(0xFFFFA000);
const _kYellow  = Color(0xFFFFEB3B);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_ChequeDue> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      final rows = await db.rawQuery('''
        SELECT ch.id, ch.numero, ch.montant, ch.dateEcheance,
               ch.banque, ch.statut,
               cl.nom as clientNom, cl.id as clientId
        FROM cheques ch
        JOIN credits cr ON ch.creditId = cr.id
        JOIN clients cl ON cr.clientId = cl.id
        WHERE ch.statut = 'EN_ATTENTE'
        ORDER BY ch.dateEcheance ASC
      ''');

      final now   = DateTime.now();
      final items = <_ChequeDue>[];

      for (final row in rows) {
        final dateStr = row['dateEcheance'] as String? ?? '';
        final date    = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final diff = date.difference(now);
        final days = diff.inDays;

        if (days <= 15) {
          items.add(_ChequeDue(
            chequeId:    row['id'] as int,
            clientId:    row['clientId'] as int,
            clientNom:   row['clientNom'] as String,
            numero:      row['numero'] as String,
            montant:     (row['montant'] as num).toDouble(),
            banque:      row['banque'] as String?,
            dateEcheance: date,
            daysLeft:    days,
          ));
        }
      }

      setState(() {
        _items   = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openClientCheques(int clientId) async {
    final db   = await DatabaseHelper.instance.database;
    final rows = await db.query('clients', where: 'id = ?', whereArgs: [clientId]);
    if (rows.isEmpty || !mounted) return;
    final client = Client.fromMap(rows.first);
    client.solde = await DatabaseHelper.instance.getSoldeClient(clientId);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(Tr.s('notifications_label'),
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Cairo',
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
            tooltip: Tr.s('try_again'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _buildCard(_items[i], theme),
                  ),
                ),
    );
  }

  Widget _buildCard(_ChequeDue item, ThemeData theme) {
    final color = _urgencyColor(item.daysLeft);
    final label = _urgencyLabel(item.daysLeft);
    final icon  = _urgencyIcon(item.daysLeft);

    return GestureDetector(
      onTap: () => _openClientCheques(item.clientId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(color: color, fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text(formatDate(item.dateEcheance),
                  style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 12)),
            ]),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.clientNom.isNotEmpty
                      ? item.clientNom[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: _kPrimary,
                      fontWeight: FontWeight.bold, fontSize: 18,
                      fontFamily: 'Cairo'),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.clientNom,
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 2),
                  Text('${Tr.s('cheque_prefix')} ${item.numero}',
                      style: const TextStyle(color: Colors.grey,
                          fontSize: 13, fontFamily: 'Cairo')),
                  if (item.banque != null)
                    Text(item.banque!,
                        style: const TextStyle(color: Colors.grey,
                            fontSize: 12, fontFamily: 'Cairo')),
                ],
              )),

              // Amount
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatMontant(item.montant),
                    style: const TextStyle(color: _kPrimary,
                        fontWeight: FontWeight.bold, fontSize: 17,
                        fontFamily: 'Cairo')),
                Text(Tr.s('currency'),
                    style: const TextStyle(color: Colors.grey,
                        fontSize: 11, fontFamily: 'Cairo')),
              ]),
            ]),
          ),

          // ── Footer ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(Tr.s('notif_go_to_client'),
                  style: TextStyle(color: Colors.grey.shade500,
                      fontSize: 11, fontFamily: 'Cairo')),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 11, color: Colors.grey.shade500),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(Tr.s('notif_no_cheques_due'),
              style: const TextStyle(color: Colors.grey,
                  fontSize: 16, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Text(Tr.s('notif_cheques_appear_here'),
              style: const TextStyle(color: Colors.grey,
                  fontSize: 13, fontFamily: 'Cairo'),
              textAlign: TextAlign.center),
        ]),
      );

  // ── Urgency helpers ──────────────────────────────────────────────────────────
  Color _urgencyColor(int days) {
    if (days <= 1) return _kRed;
    if (days <= 7) return _kOrange;
    return _kYellow;
  }

  IconData _urgencyIcon(int days) {
    if (days < 0)  return Icons.error;
    if (days <= 1) return Icons.warning_rounded;
    if (days <= 3) return Icons.access_time;
    return Icons.notifications_outlined;
  }

  String _urgencyLabel(int days) {
    if (days < 0)  return '${Tr.s('notif_overdue')} ${-days} ${Tr.s('notif_days_ago')}';
    if (days == 0) return Tr.s('notif_due_today');
    if (days == 1) return Tr.s('notif_due_tomorrow');
    if (days <= 7) return '${Tr.s('notif_due_in')} $days ${Tr.s('notif_days')}';
    return '${Tr.s('notif_due_in')} $days ${Tr.s('notif_day')}';
  }
}

// ── Data class ─────────────────────────────────────────────────────────────────
class _ChequeDue {
  final int      chequeId;
  final int      clientId;
  final String   clientNom;
  final String   numero;
  final double   montant;
  final String?  banque;
  final DateTime dateEcheance;
  final int      daysLeft;

  _ChequeDue({
    required this.chequeId,
    required this.clientId,
    required this.clientNom,
    required this.numero,
    required this.montant,
    this.banque,
    required this.dateEcheance,
    required this.daysLeft,
  });
}