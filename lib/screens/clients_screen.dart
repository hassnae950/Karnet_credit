import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';
import 'client_detail_screen.dart';
import 'add_client_sheet.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed     = Color(0xFFD32F2F);
const _kGreen   = Color(0xFF388E3C);
const _kBlue    = Color(0xFF1976D2);

class ClientsScreen extends StatefulWidget {
  final String type;
  final VoidCallback? onStatsChanged;

  const ClientsScreen({
    super.key,
    this.type = 'CLIENT',
    this.onStatsChanged,
  });

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Client> _clients = [];
  bool _loading = true;
  String _search = '';

  double _totalCredit  = 0;
  double _totalRestant = 0;
  double _totalPaye    = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final clients = await DatabaseHelper.instance.getClientsByType(widget.type);
    for (var c in clients) {
      c.solde = await DatabaseHelper.instance.getSoldeClient(c.id!);
    }
    final stats = await DatabaseHelper.instance.getStatsByType(widget.type);
    if (mounted) {
      setState(() {
        _clients      = clients;
        _totalCredit  = stats['totalCredit']  ?? 0;
        _totalRestant = stats['totalRestant'] ?? 0;
        _totalPaye    = stats['totalPaye']    ?? 0;
        _loading      = false;
      });
    }
    widget.onStatsChanged?.call();
  }

  List<Client> get _filtered => _clients
      .where((c) =>
          c.nom.toLowerCase().contains(_search.toLowerCase()) ||
          (c.telephone ?? '').contains(_search))
      .toList();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // ── Search bar (pinned) ──────────────────────────────────────────────
        SliverAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: theme.scaffoldBackgroundColor,
          pinned: true,
          floating: false,
          elevation: 0,
          toolbarHeight: 64,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      textAlign: Tr.textAlignStart,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      decoration: InputDecoration(
                        hintText: Tr.s('search'),
                        hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        prefixIcon: const Icon(Icons.search, color: _kPrimary),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Stats chips ──────────────────────────────────────────────────────
        if (!_loading) SliverToBoxAdapter(child: _statsBar()),

        // ── Count label ──────────────────────────────────────────────────────
        if (!_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 4, top: 2),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '${_filtered.length} ${widget.type == 'CLIENT' ? Tr.s('client_count') : Tr.s('supplier_count')}',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontFamily: 'Cairo'),
                ),
              ),
            ),
          ),

        // ── Body ─────────────────────────────────────────────────────────────
        if (_loading)
          const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: _kPrimary)),
          )
        else if (_filtered.isEmpty)
          SliverFillRemaining(child: _buildEmpty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _clientCard(_filtered[i]),
                ),
                childCount: _filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────────────────
  Widget _statsBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(
          children: [
            _statChip(Tr.s('took'),      _totalCredit,  _kGreen, _kGreen.withOpacity(0.12)),
            const SizedBox(width: 8),
            _statChip(Tr.s('remaining'), _totalRestant, _kRed,   _kRed.withOpacity(0.12)),
            const SizedBox(width: 8),
            _statChip(Tr.s('gave'),      _totalPaye,    _kBlue,  _kBlue.withOpacity(0.12)),
          ],
        ),
      );

  Widget _statChip(
          String label, double amount, Color color, Color bg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontFamily: 'Cairo')),
              const SizedBox(height: 2),
              Text(
                formatMontant(amount),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Cairo'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(Tr.s('currency'),
                  style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'Cairo')),
            ],
          ),
        ),
      );

  // ── Client card ────────────────────────────────────────────────────────────
  Widget _clientCard(Client client) => GestureDetector(
        onTap: () => _ouvrirClient(client),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              // Balance (start side — left in LTR, right in RTL via Directionality)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMontant(client.solde),
                    style: TextStyle(
                      color: client.solde > 0 ? _kRed : _kGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    client.solde > 0 ? Tr.s('took') : Tr.s('settled'),
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontFamily: 'Cairo'),
                  ),
                ],
              ),
              const Spacer(),
              // Client info (end side)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(client.nom,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo')),
                  if (client.telephone != null)
                    Text(client.telephone!,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: 'Cairo')),
                  if (client.company != null)
                    Text(client.company!,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontFamily: 'Cairo')),
                ],
              ),
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  client.initiales,
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.type == 'CLIENT'
                  ? Icons.people_outline
                  : Icons.local_shipping_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              widget.type == 'CLIENT'
                  ? Tr.s('no_clients')
                  : Tr.s('no_suppliers'),
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            Text(
              widget.type == 'CLIENT'
                  ? Tr.s('add_first_client')
                  : Tr.s('add_first_supplier'),
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _ouvrirClient(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ClientDetailScreen(client: client)),
    ).then((_) => _loadData());
  }
}