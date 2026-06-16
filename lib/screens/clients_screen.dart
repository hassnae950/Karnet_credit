import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';
import 'client_detail_screen.dart';
import '../services/pdf_service.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed = Color(0xFFD32F2F);
const _kGreen = Color(0xFF388E3C);
const _kBlue = Color(0xFF1976D2);

// ── Sort options ──────────────────────────────────────────────────────────────
enum SortOption { nameAZ, nameZA, debtHigh, debtLow, recentActivity, oldest }

// ── Filter options ────────────────────────────────────────────────────────────
enum FilterOption { all, withDebt, settled, hasCheque }

class ClientsScreen extends StatefulWidget {
  final String type;
  final VoidCallback? onStatsChanged;

  const ClientsScreen({
    super.key,
    this.type = 'CLIENT',
    this.onStatsChanged,
  });

  @override
  State<ClientsScreen> createState() => ClientsScreenState();
}

class ClientsScreenState extends State<ClientsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Client> _clients = [];
  bool _loading = true;
  String _search = '';

  double _totalCredit = 0;
  double _totalRestant = 0;
  double _totalPaye = 0;

  SortOption _sort = SortOption.recentActivity;
  FilterOption _filter = FilterOption.all;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final clients = await DatabaseHelper.instance.getClientsByType(widget.type);

    for (var c in clients) {
      c.solde = await DatabaseHelper.instance.getSoldeClient(c.id!);
      c.lastActivityDate =
          await DatabaseHelper.instance.getLastActivityDate(c.id!);
      c.chequeCount = await DatabaseHelper.instance.getClientChequeCount(c.id!);
    }

    final stats = await DatabaseHelper.instance.getStatsByType(widget.type);

    if (mounted) {
      setState(() {
        _clients = clients;
        _totalCredit = stats['totalCredit'] ?? 0;
        _totalRestant = stats['totalRestant'] ?? 0;
        _totalPaye = stats['totalPaye'] ?? 0;
        _loading = false;
      });
    }
    widget.onStatsChanged?.call();
  }

  // ── Filtered + sorted list ────────────────────────────────────────────────
  List<Client> get _processed {
    var list = _clients.where((c) {
      final searchLower = _search.toLowerCase();
      final matchName = c.nom.toLowerCase().contains(searchLower);
      final matchCompany =
          (c.company ?? '').toLowerCase().contains(searchLower);
      final matchPhone = (c.telephone ?? '').contains(_search);

      if (!matchName && !matchCompany && !matchPhone) return false;

      switch (_filter) {
        case FilterOption.all:
          return true;
        case FilterOption.withDebt:
          return c.solde > 0;
        case FilterOption.settled:
          return c.solde <= 0;
        case FilterOption.hasCheque:
          return (c.chequeCount ?? 0) > 0;
      }
    }).toList();

    switch (_sort) {
      case SortOption.nameAZ:
        list.sort((a, b) => a.nom.compareTo(b.nom));
        break;
      case SortOption.nameZA:
        list.sort((a, b) => b.nom.compareTo(a.nom));
        break;
      case SortOption.debtHigh:
        list.sort((a, b) => b.solde.compareTo(a.solde));
        break;
      case SortOption.debtLow:
        list.sort((a, b) => a.solde.compareTo(b.solde));
        break;
      case SortOption.recentActivity:
        list.sort((a, b) {
          if (a.lastActivityDate == null && b.lastActivityDate == null) {
            return a.dateCreation.compareTo(b.dateCreation);
          }
          if (a.lastActivityDate == null) return 1;
          if (b.lastActivityDate == null) return -1;
          return b.lastActivityDate!.compareTo(a.lastActivityDate!);
        });
        break;
      case SortOption.oldest:
        list.sort((a, b) => (a.dateCreation).compareTo(b.dateCreation));
        break;
    }

    return list;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        currentSort: _sort,
        currentFilter: _filter,
        onApply: (sort, filter) {
          setState(() {
            _sort = sort;
            _filter = filter;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final processed = _processed;
    final hasFilters =
        _sort != SortOption.recentActivity || _filter != FilterOption.all;

    return CustomScrollView(
      slivers: [
        // ── Search bar ───────────────────────────────────────────────────────
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
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasFilters ? _kPrimary : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.tune,
                              color: hasFilters ? Colors.white : _kPrimary),
                          if (hasFilters)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _printAllClients,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined,
                          color: _kPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Stats chips ──────────────────────────────────────────────────────
        if (!_loading) SliverToBoxAdapter(child: _statsBar()),

        // ── Count + active filter label ──────────────────────────────────────
        if (!_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.only(right: 20, left: 20, bottom: 4, top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasFilters)
                    GestureDetector(
                      onTap: () => setState(() {
                        _sort = SortOption.recentActivity;
                        _filter = FilterOption.all;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.close, size: 12, color: _kPrimary),
                          const SizedBox(width: 4),
                          Text(Tr.s('clear_filter'),
                              style: const TextStyle(
                                  color: _kPrimary,
                                  fontSize: 11,
                                  fontFamily: 'Cairo')),
                        ]),
                      ),
                    )
                  else
                    const SizedBox(),
                  Text(
                    '${processed.length} ${widget.type == 'CLIENT' ? Tr.s('client_count') : Tr.s('supplier_count')}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ),

        // ── Body ─────────────────────────────────────────────────────────────
        if (_loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: _kPrimary)),
          )
        else if (processed.isEmpty)
          SliverFillRemaining(child: _buildEmpty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _clientCard(processed[i]),
                ),
                childCount: processed.length,
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
            _statChip(
                Tr.s('took'), _totalPaye, _kGreen, _kGreen.withOpacity(0.12)),
            _statChip(
                Tr.s('gave'), _totalCredit, _kRed, _kRed.withOpacity(0.12)),
            const SizedBox(width: 8),
            _statChip(Tr.s('remaining'), _totalRestant, _kBlue,
                _kBlue.withOpacity(0.12)),
            const SizedBox(width: 8),
          ],
        ),
      );

  Widget _statChip(String label, double amount, Color color, Color bg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(label,
                style:
                    TextStyle(color: color, fontSize: 11, fontFamily: 'Cairo')),
            const SizedBox(height: 2),
            Text(formatMontant(amount),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Cairo'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(Tr.s('currency'),
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'Cairo')),
          ]),
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
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(formatMontant(client.solde),
                  style: TextStyle(
                    color: client.solde > 0 ? _kRed : _kGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                  )),
              Text(client.solde > 0 ? Tr.s('took') : Tr.s('settled'),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
              if ((client.chequeCount ?? 0) > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 10, color: Color(0xFFFFA000)),
                      const SizedBox(width: 3),
                      Text('${client.chequeCount}',
                          style: const TextStyle(
                            color: Color(0xFFFFA000),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          )),
                    ],
                  ),
                ),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(client.nom,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo')),
              if (client.telephone != null)
                Text(client.telephone!,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              if (client.company != null)
                Text(client.company!,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
            ]),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(client.initiales,
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Cairo')),
            ),
          ]),
        ),
      );

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            widget.type == 'CLIENT'
                ? Icons.people_outline
                : Icons.local_shipping_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _filter != FilterOption.all || _search.isNotEmpty
                ? Tr.s('no_results')
                : widget.type == 'CLIENT'
                    ? Tr.s('no_clients')
                    : Tr.s('no_suppliers'),
            style: const TextStyle(
                color: Colors.grey, fontSize: 16, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 8),
          if (_filter != FilterOption.all || _search.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _search = '';
                _filter = FilterOption.all;
                _sort = SortOption.recentActivity;
              }),
              child: Text(Tr.s('clear_filter'),
                  style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                      decoration: TextDecoration.underline)),
            )
          else
            Text(
              widget.type == 'CLIENT'
                  ? Tr.s('add_first_client')
                  : Tr.s('add_first_supplier'),
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
        ]),
      );
  Future<void> _printAllClients() async {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              widget.type == 'CLIENT'
                  ? Tr.s('no_clients')
                  : Tr.s('no_suppliers'),
              style: const TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    try {
      final rows =
          await DatabaseHelper.instance.getClientsReportData(widget.type);
      await PdfService.instance.printAllClientsReport(rows, widget.type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${Tr.s('error_prefix')} $e',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red));
      }
    }
  }

  void _ouvrirClient(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    ).then((_) => loadData());
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════════
class _FilterSheet extends StatefulWidget {
  final SortOption currentSort;
  final FilterOption currentFilter;
  final void Function(SortOption, FilterOption) onApply;

  const _FilterSheet({
    required this.currentSort,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SortOption _sort;
  late FilterOption _filter;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Title
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => setState(() {
              _sort = SortOption.recentActivity;
              _filter = FilterOption.all;
            }),
            child: Text(Tr.s('clear_all'),
                style: const TextStyle(
                    color: _kPrimary, fontFamily: 'Cairo', fontSize: 14)),
          ),
          Text(Tr.s('sort_filter_title'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo')),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.grey),
          ),
        ]),
        const SizedBox(height: 24),

        // ── Sort ──────────────────────────────────────────────────────────────
        _sectionLabel(Tr.s('sort_label')),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _sortChip(SortOption.recentActivity, Tr.s('sort_recent')),
          _sortChip(SortOption.debtHigh, Tr.s('sort_debt_high')),
          _sortChip(SortOption.debtLow, Tr.s('sort_debt_low')),
          _sortChip(SortOption.nameAZ, Tr.s('sort_name_az')),
          _sortChip(SortOption.nameZA, Tr.s('sort_name_za')),
          _sortChip(SortOption.oldest, Tr.s('sort_oldest')),
        ]),
        const SizedBox(height: 20),

        // ── Filter ────────────────────────────────────────────────────────────
        _sectionLabel(Tr.s('filter_label')),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _filterChip(FilterOption.all, Tr.s('filter_all')),
          _filterChip(FilterOption.withDebt, Tr.s('filter_with_debt')),
          _filterChip(FilterOption.settled, Tr.s('filter_settled')),
          _filterChip(FilterOption.hasCheque, Tr.s('filter_has_cheque')),
        ]),
        const SizedBox(height: 28),

        // Apply
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              widget.onApply(_sort, _filter);
              Navigator.pop(context);
            },
            child: Text(Tr.s('apply'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Align(
        alignment: Alignment.centerRight,
        child: Text(label,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600)),
      );

  Widget _sortChip(SortOption option, String label) {
    final selected = _sort == option;
    return GestureDetector(
      onTap: () => setState(() => _sort = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : _kPrimary,
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _filterChip(FilterOption option, String label) {
    final selected = _filter == option;
    return GestureDetector(
      onTap: () => setState(() => _filter = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : _kPrimary,
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}
