import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';

class PdfService {
  static final PdfService instance = PdfService._();
  PdfService._();

  // ── Colors ───────────────────────────────────────────────────────────────────
  static const _green  = PdfColor.fromInt(0xFF1B8A6B);
  static const _red    = PdfColor.fromInt(0xFFD32F2F);
  static const _grey   = PdfColor.fromInt(0xFF757575);
  static const _bgGrey = PdfColor.fromInt(0xFFF5F6FA);

  // ── Load fonts ───────────────────────────────────────────────────────────────
  Future<pw.Font> _loadFont(String asset) async {
    final data = await rootBundle.load(asset);
    return pw.Font.ttf(data);
  }

  // ── Translated labels ────────────────────────────────────────────────────────
  String get _total       => Tr.s('total_label');
  String get _paid        => Tr.s('paid_label');
  String get _remaining   => Tr.s('remaining');
  String get _openCredit  => Tr.s('credit_label');
  String get _txDetails   => Tr.s('transactions');
  String get _noTx        => Tr.s('no_transactions');
  String get _payments    => Tr.s('payment_label');
  String get _settled     => Tr.s('settled');
  String get _ongoing     => Tr.s('took');
  String get _appName     => Tr.s('app_title');
  String get _reportLabel => Tr.s('report');
  String get _currency    => Tr.s('currency'); // ✅ درهم / MAD / DH حسب اللغة
  String get _balance     => Tr.s('balance');
  String get _summary     => Tr.currentLang == 'fr'
      ? 'Résumé client'
      : (Tr.currentLang == 'en' ? 'Client Summary' : 'ملخص العميل');
  String get _issueDate   => Tr.currentLang == 'fr'
      ? "Date d'émission:"
      : (Tr.currentLang == 'en' ? 'Issue date:' : 'تاريخ الإصدار:');
  String get _pageOf => Tr.currentLang == 'fr'
      ? 'Page'
      : (Tr.currentLang == 'en' ? 'Page' : 'صفحة');
  String get _of => Tr.currentLang == 'fr'
      ? 'sur'
      : (Tr.currentLang == 'en' ? 'of' : 'من');
  String get _createdBy => Tr.currentLang == 'fr'
      ? 'Créé par $_appName'
      : (Tr.currentLang == 'en'
          ? 'Created by $_appName'
          : 'تم الإنشاء بتطبيق $_appName');

  // ── Arabic text helper ───────────────────────────────────────────────────────
  pw.Widget _txt(String text, pw.TextStyle style, {pw.TextAlign? align}) {
    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(text);
    return pw.Directionality(
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Text(text, style: style,
          textAlign: align ?? pw.TextAlign.start),
    );
  }

  // ── Shared vertical line ─────────────────────────────────────────────────────
  pw.Widget _vLine() =>
      pw.Container(width: 0.5, height: 36, color: PdfColors.grey300);

  // ── FOOTER (shared) ──────────────────────────────────────────────────────────
  pw.Widget _buildFooter(pw.Context ctx, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$_pageOf ${ctx.pageNumber} $_of ${ctx.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
          pw.Text(_createdBy,
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SINGLE CLIENT REPORT — جدول المعاملات
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> printClientReport(
    Client client,
    List<Credit> credits,
    Map<int, List<Paiement>> paiementsMap,
  ) async {
    final font     = await _loadFont('assets/fonts/Cairo-Regular.ttf');
    final fontBold = await _loadFont('assets/fonts/Cairo-Bold.ttf');

    final isAr    = Tr.currentLang == 'ar';
    final pageDir = isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    // ── بناء قائمة المعاملات مرتبة بالتاريخ ────────────────────────────────
    final List<Map<String, dynamic>> txList = [];

    for (final credit in credits) {
      txList.add({
        'date'  : credit.dateCredit,
        'note'  : credit.description ?? '',
        'credit': credit.montantTotal,
        'debit' : 0.0,
      });
      final paiements = paiementsMap[credit.id!] ?? [];
      for (final p in paiements) {
        txList.add({
          'date'  : p.datePaiement,
          'note'  : p.note ?? '',
          'credit': 0.0,
          'debit' : p.montant,
        });
      }
    }

    txList.sort((a, b) =>
        (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    double running = 0;
    for (final tx in txList) {
      running += (tx['credit'] as double) - (tx['debit'] as double);
      tx['balance'] = running;
    }

    final totalCredit =
        txList.fold(0.0, (s, t) => s + (t['credit'] as double));
    final totalDebit =
        txList.fold(0.0, (s, t) => s + (t['debit'] as double));
    final solde = totalCredit - totalDebit;

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pageDir,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _buildClientHeader(
          client, solde, totalCredit, totalDebit, txList.length, font, fontBold),
      footer: (ctx) => _buildFooter(ctx, font),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        if (txList.isEmpty)
          pw.Center(
              child: pw.Text(_noTx,
                  style: pw.TextStyle(font: font, color: _grey)))
        else
          _txTable(txList, totalCredit, totalDebit, font, fontBold),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ── Header ديال عميل واحد ────────────────────────────────────────────────────
  pw.Widget _buildClientHeader(
      Client client,
      double solde,
      double totalCredit,
      double totalDebit,
      int txCount,
      pw.Font font,
      pw.Font bold) {
    final nameRow = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(formatDate(DateTime.now()),
              style: pw.TextStyle(font: font, color: _grey, fontSize: 10)),
          pw.Text('$_appName — $_reportLabel',
              style: pw.TextStyle(font: font, color: _grey, fontSize: 9)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Directionality(
            textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(client.nom)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            child: pw.Text(client.nom,
                style: pw.TextStyle(font: bold, fontSize: 20, color: _green)),
          ),
          if (client.telephone != null)
            pw.Text(client.telephone!,
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
          if (client.company != null)
            pw.Text(client.company!,
                style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
        ]),
      ],
    );

    final statsBar = pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: _bgGrey,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _clientStatCard(Tr.s('client_count'), null, '$txCount',
              PdfColors.black, font, bold),
          _vLine(),
          _clientStatCard(_ongoing, totalCredit, null,
              PdfColors.green700, font, bold),
          _vLine(),
          _clientStatCard(_paid, totalDebit, null,
              PdfColors.blue700, font, bold),
          _vLine(),
          _clientStatCard(_balance, solde, null,
              solde > 0 ? PdfColors.red700 : PdfColors.green700, font, bold),
        ],
      ),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 0),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _green, width: 2)),
      ),
      child: pw.Column(children: [
        nameRow,
        statsBar,
        pw.SizedBox(height: 12),
      ]),
    );
  }

  // ── كارد الإحصاء (عميل واحد) ✅ _currency بدل 'درهم' ─────────────────────────
  pw.Widget _clientStatCard(String label, double? amount, String? countStr,
      PdfColor color, pw.Font font, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (amount != null) ...[
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              amount.toStringAsFixed(2).replaceAll('.', ','),
              style: pw.TextStyle(font: bold, fontSize: 11, color: color),
              textAlign: pw.TextAlign.center,
            ),
          ),
          // ✅ FIX 1: _currency بدل 'درهم' + ltr
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(_currency,
                style: pw.TextStyle(font: font, fontSize: 8, color: color),
                textAlign: pw.TextAlign.center),
          ),
        ] else
          pw.Text(countStr ?? '',
              style: pw.TextStyle(font: bold, fontSize: 13, color: color),
              textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 3),
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
            textAlign: pw.TextAlign.center),
      ],
    );
  }

  // ── جدول المعاملات ────────────────────────────────────────────────────────────
  pw.Widget _txTable(List<Map<String, dynamic>> txList, double totalCredit,
      double totalDebit, pw.Font font, pw.Font bold) {

    pw.Widget cell(String text,
            {pw.Font? f, PdfColor? color, double size = 9,
            pw.TextAlign align = pw.TextAlign.center}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: pw.Text(text,
              style: pw.TextStyle(
                  font: f ?? font, fontSize: size, color: color),
              textAlign: align),
        );

    // ✅ FIX 2: amountCell كتستعمل _currency بدل 'درهم'
    pw.Widget amountCell(double amount,
        {PdfColor? color, double size = 9, bool showZero = false}) {
      if (amount == 0 && !showZero) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: pw.Text('-',
              style: pw.TextStyle(font: font, fontSize: size, color: _grey),
              textAlign: pw.TextAlign.center),
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(
                amount.toStringAsFixed(2).replaceAll('.', ','),
                style: pw.TextStyle(font: bold, fontSize: size, color: color),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // ✅ FIX 2
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(_currency,
                  style: pw.TextStyle(
                      font: font,
                      fontSize: size - 1,
                      color: color ?? _grey),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      );
    }

    pw.Widget headerCell(String text) => pw.Container(
          color: _green,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: _txt(text,
                pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
                align: pw.TextAlign.center),
          ),
        );

    final headerRow = pw.TableRow(children: [
      headerCell(_balance),
      headerCell(_paid),
      headerCell(_ongoing),
      headerCell(Tr.currentLang == 'ar'
          ? 'ملاحظة'
          : (Tr.currentLang == 'fr' ? 'Note' : 'Note')),
      headerCell(Tr.currentLang == 'ar'
          ? 'التاريخ'
          : (Tr.currentLang == 'fr' ? 'Date' : 'Date')),
      headerCell('#'),
    ]);

    final dataRows = <pw.TableRow>[];
    for (var i = 0; i < txList.length; i++) {
      final tx      = txList[i];
      final balance = tx['balance'] as double;
      final credit  = tx['credit']  as double;
      final debit   = tx['debit']   as double;
      final note    = tx['note']    as String;
      final date    = tx['date']    as DateTime;

      dataRows.add(pw.TableRow(
        decoration: i.isOdd
            ? const pw.BoxDecoration(color: _bgGrey)
            : const pw.BoxDecoration(),
        children: [
          amountCell(balance,
              color: balance > 0 ? PdfColors.red700 : PdfColors.green700,
              showZero: true),
          amountCell(debit,  color: PdfColors.blue700),
          amountCell(credit, color: PdfColors.green700),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: _txt(note,
                pw.TextStyle(font: font, fontSize: 8, color: _grey),
                align: pw.TextAlign.center),
          ),
          cell(formatDate(date), size: 8),
          cell('${i + 1}'),
        ],
      ));
    }

    final totalRow = pw.TableRow(
      decoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F5E9)),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: _txt(
              Tr.currentLang == 'ar'
                  ? 'إجمالي الدفع'
                  : (Tr.currentLang == 'fr' ? 'Total' : 'Total'),
              pw.TextStyle(font: bold, fontSize: 9),
              align: pw.TextAlign.center),
        ),
        amountCell(totalDebit,  color: PdfColors.blue700,  size: 10),
        amountCell(totalCredit, color: PdfColors.green700, size: 10),
        cell(''),
        cell(''),
        cell(''),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(2.0),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(0.6),
      },
      children: [headerRow, ...dataRows, totalRow],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  QUICK SUMMARY (A5)
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> printClientSummary(Client client, double solde) async {
    final font     = await _loadFont('assets/fonts/Cairo-Regular.ttf');
    final fontBold = await _loadFont('assets/fonts/Cairo-Bold.ttf');

    final pdf = pw.Document();
    final isArSummary = Tr.currentLang == 'ar';

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      textDirection:
          isArSummary ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(_appName,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 28, color: _green)),
          pw.SizedBox(height: 4),
          pw.Text(_summary,
              style: pw.TextStyle(font: font, fontSize: 13, color: _grey)),
          pw.SizedBox(height: 24),
          pw.Divider(color: _green, thickness: 2),
          pw.SizedBox(height: 16),
          pw.Directionality(
            textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(client.nom)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            child: pw.Text(client.nom,
                style: pw.TextStyle(font: fontBold, fontSize: 22),
                textAlign: pw.TextAlign.center),
          ),
          if (client.telephone != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(client.telephone!,
                style: pw.TextStyle(
                    font: font, fontSize: 14, color: _grey),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 24),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: solde > 0
                  ? const PdfColor.fromInt(0xFFFFEBEE)
                  : const PdfColor.fromInt(0xFFE8F5E9),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(children: [
              pw.Text(_balance,
                  style: pw.TextStyle(
                      font: font, fontSize: 12, color: _grey)),
              pw.SizedBox(height: 6),
              pw.Text(formatMontant(solde),
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 28,
                      color: solde > 0
                          ? PdfColors.red700
                          : PdfColors.green700),
                  textAlign: pw.TextAlign.center),
            ]),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text('$_issueDate ${formatDate(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
              textAlign: pw.TextAlign.center),
          pw.Text(_createdBy,
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
              textAlign: pw.TextAlign.center),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  ALL CLIENTS REPORT — تقرير شامل لجميع العملاء/الموردين
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> printAllClientsReport(
    List<Map<String, dynamic>> rows,
    String type,
  ) async {
    final font     = await _loadFont('assets/fonts/Cairo-Regular.ttf');
    final fontBold = await _loadFont('assets/fonts/Cairo-Bold.ttf');

    final isAr    = Tr.currentLang == 'ar';
    final pageDir = isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final totalCredit =
        rows.fold(0.0, (s, r) => s + (r['totalCredit'] as double));
    final totalPaye =
        rows.fold(0.0, (s, r) => s + (r['totalPaye'] as double));
    final totalSolde =
        rows.fold(0.0, (s, r) => s + (r['solde'] as double));

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    final title = type == 'CLIENT'
        ? (Tr.currentLang == 'fr'
            ? 'Rapport des clients'
            : (Tr.currentLang == 'en' ? 'Clients Report' : 'تقرير العملاء'))
        : (Tr.currentLang == 'fr'
            ? 'Rapport des fournisseurs'
            : (Tr.currentLang == 'en'
                ? 'Suppliers Report'
                : 'تقرير الموردين'));

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pageDir,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _buildAllClientsHeader(title, font, fontBold),
      footer: (ctx) => _buildFooter(ctx, font),
      build: (ctx) => [
        _allClientsSummaryRow(
            rows.length, totalCredit, totalPaye, totalSolde, font, fontBold),
        pw.SizedBox(height: 16),
        _allClientsTable(
            rows, totalCredit, totalPaye, totalSolde, font, fontBold),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ── Header ديال تقرير جميع العملاء ──────────────────────────────────────────
  pw.Widget _buildAllClientsHeader(
      String title, pw.Font font, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _green, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(formatDate(DateTime.now()),
                style: pw.TextStyle(font: font, color: _grey, fontSize: 10)),
            pw.Text(_appName,
                style: pw.TextStyle(font: font, color: _grey, fontSize: 9)),
          ]),
          pw.Text(title,
              style: pw.TextStyle(font: bold, fontSize: 18, color: _green)),
        ],
      ),
    );
  }

  // ── شريط التوتال ديال جميع العملاء ✅ FIX 3 ──────────────────────────────────
  pw.Widget _allClientsSummaryRow(int count, double totalCredit,
      double totalPaye, double totalSolde, pw.Font font, pw.Font bold) {
    pw.Widget summCard(
            String label, double? amount, String? countStr, PdfColor color) =>
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (amount != null) ...[
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  amount.toStringAsFixed(2).replaceAll('.', ','),
                  style: pw.TextStyle(font: bold, fontSize: 11, color: color),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // ✅ FIX 3
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(_currency,
                    style: pw.TextStyle(font: font, fontSize: 8, color: color),
                    textAlign: pw.TextAlign.center),
              ),
            ] else
              pw.Text(countStr ?? '',
                  style: pw.TextStyle(font: bold, fontSize: 13, color: color),
                  textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 3),
            pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
                textAlign: pw.TextAlign.center),
          ],
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _bgGrey,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          summCard(Tr.s('client_count'), null, '$count', PdfColors.black),
          _vLine(),
          summCard(_ongoing, totalCredit, null, PdfColors.green700),
          _vLine(),
          summCard(_paid, totalPaye, null, PdfColors.blue700),
          _vLine(),
          summCard(_balance, totalSolde, null,
              totalSolde > 0 ? PdfColors.red700 : PdfColors.green700),
        ],
      ),
    );
  }

  // ── جدول جميع العملاء ✅ FIX 4 ───────────────────────────────────────────────
  pw.Widget _allClientsTable(
      List<Map<String, dynamic>> rows,
      double totalCredit,
      double totalPaye,
      double totalSolde,
      pw.Font font,
      pw.Font bold) {
    pw.Widget cell(String text,
            {pw.Font? f, PdfColor? color, double size = 9}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: pw.Text(text,
              style: pw.TextStyle(
                  font: f ?? font, fontSize: size, color: color),
              textAlign: pw.TextAlign.center),
        );

    // ✅ FIX 4: amountCell كتستعمل _currency بدل 'درهم'
    pw.Widget amountCell(double amount,
        {PdfColor? color, double size = 9}) {
      final numStr = amount.toStringAsFixed(2).replaceAll('.', ',');
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(numStr,
                  style: pw.TextStyle(
                      font: bold, fontSize: size, color: color),
                  textAlign: pw.TextAlign.center),
            ),
            // ✅ FIX 4
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(_currency,
                  style: pw.TextStyle(
                      font: font,
                      fontSize: size - 1,
                      color: color ?? _grey),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      );
    }

    pw.Widget headerCell(String text) => pw.Container(
          color: _green,
          child: pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: _txt(text,
                pw.TextStyle(
                    font: bold, fontSize: 10, color: PdfColors.white),
                align: pw.TextAlign.center),
          ),
        );

    final headerRow = pw.TableRow(children: [
      headerCell(_balance),
      headerCell(_paid),
      headerCell(_ongoing),
      headerCell(Tr.s('phone')),
      headerCell(Tr.s('client')),
      headerCell('#'),
    ]);

    final dataRows = <pw.TableRow>[];
    for (var i = 0; i < rows.length; i++) {
      final r     = rows[i];
      final solde = r['solde'] as double;
      dataRows.add(pw.TableRow(
        decoration: i.isOdd
            ? const pw.BoxDecoration(color: _bgGrey)
            : const pw.BoxDecoration(),
        children: [
          amountCell(solde,
              color: solde > 0 ? PdfColors.red700 : PdfColors.green700),
          amountCell(r['totalPaye']   as double, color: PdfColors.blue700),
          amountCell(r['totalCredit'] as double, color: PdfColors.green700),
          cell(r['telephone'] as String? ?? '-'),
          cell(r['nom'] as String, f: bold),
          cell('${i + 1}'),
        ],
      ));
    }

    final totalRow = pw.TableRow(
      decoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F5E9)),
      children: [
        amountCell(totalSolde,
            color: totalSolde > 0 ? PdfColors.red700 : PdfColors.green700,
            size: 10),
        amountCell(totalPaye,   color: PdfColors.blue700,  size: 10),
        amountCell(totalCredit, color: PdfColors.green700, size: 10),
        cell(''),
        cell(_total, f: bold),
        cell(''),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(2.4),
        5: pw.FlexColumnWidth(0.6),
      },
      children: [headerRow, ...dataRows, totalRow],
    );
  }
}