import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models.dart';
import '../utils/helpers.dart';

class PdfService {
  static final PdfService instance = PdfService._();
  PdfService._();

  // ── Colors ──
  static const _green  = PdfColor.fromInt(0xFF1B8A6B);
  static const _red    = PdfColor.fromInt(0xFFD32F2F);
  static const _blue   = PdfColor.fromInt(0xFF1976D2);
  static const _grey   = PdfColor.fromInt(0xFF757575);
  static const _bgGrey = PdfColor.fromInt(0xFFF5F6FA);

  // ────────────────────────────────────────────────
  //  MAIN: Print full client report
  // ────────────────────────────────────────────────
  Future<void> printClientReport(
    Client client,
    List<Credit> credits,
    Map<int, List<Paiement>> paiementsMap,
  ) async {
    final font     = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final totalDonne   = credits.fold(0.0, (s, c) => s + c.montantTotal);
    final totalRestant = credits.fold(0.0, (s, c) => s + c.montantRestant);
    final totalPaye    = totalDonne - totalRestant;
    final nbOuverts    = credits.where((c) => !c.estSolde).length;

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _buildHeader(client, font, fontBold),
      footer: (ctx) => _buildFooter(ctx, font),
      build: (ctx) => [
        // ── Summary cards ──
        _summaryRow(totalDonne, totalPaye, totalRestant, nbOuverts, font, fontBold),
        pw.SizedBox(height: 24),

        // ── Section title ──
        _sectionTitle('تفاصيل المعاملات', font, fontBold),
        pw.SizedBox(height: 12),

        // ── Credits list ──
        if (credits.isEmpty)
          pw.Center(child: pw.Text('ما كاين حتى معاملة',
              style: pw.TextStyle(font: font, color: _grey)))
        else
          ...credits.map((credit) {
            final paiements = paiementsMap[credit.id!] ?? [];
            return _creditBlock(credit, paiements, font, fontBold);
          }),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ────────────────────────────────────────────────
  //  HEADER
  // ────────────────────────────────────────────────
  pw.Widget _buildHeader(Client client, pw.Font font, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _green, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Left: date
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(formatDate(DateTime.now()),
                style: pw.TextStyle(font: font, color: _grey, fontSize: 10)),
            pw.Text('كارنيه — تقرير العميل',
                style: pw.TextStyle(font: font, color: _grey, fontSize: 9)),
          ]),

          // Right: client info
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(client.nom,
                style: pw.TextStyle(font: bold, fontSize: 22, color: _green)),
            if (client.telephone != null)
              pw.Text(client.telephone!,
                  style: pw.TextStyle(font: font, fontSize: 11, color: _grey)),
            if (client.company != null)
              pw.Text(client.company!,
                  style: pw.TextStyle(font: font, fontSize: 11, color: _grey)),
            if (client.adresse != null)
              pw.Text(client.adresse!,
                  style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
          ]),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  FOOTER
  // ────────────────────────────────────────────────
  pw.Widget _buildFooter(pw.Context ctx, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
          pw.Text('تم الإنشاء بتطبيق كارنيه',
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  SUMMARY ROW  (4 cards)
  // ────────────────────────────────────────────────
  pw.Widget _summaryRow(
    double total, double paye, double restant, int nbOuverts,
    pw.Font font, pw.Font bold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _bgGrey,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryCard('المجموع',      formatMontant(total),   PdfColors.black,     font, bold),
          _vLine(),
          _summaryCard('مدفوع',        formatMontant(paye),    PdfColors.green700,  font, bold),
          _vLine(),
          _summaryCard('الباقي',       formatMontant(restant), PdfColors.red700,    font, bold),
          _vLine(),
          _summaryCard('كريدي مفتوح', '$nbOuverts',           PdfColors.orange700, font, bold),
        ],
      ),
    );
  }

  pw.Widget _summaryCard(String label, String value, PdfColor color,
      pw.Font font, pw.Font bold) =>
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Text(value,
          style: pw.TextStyle(font: bold, fontSize: 13, color: color),
          textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 3),
      pw.Text(label,
          style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
          textAlign: pw.TextAlign.center),
    ]);

  pw.Widget _vLine() => pw.Container(
    width: 0.5, height: 36, color: PdfColors.grey300);

  // ────────────────────────────────────────────────
  //  SECTION TITLE
  // ────────────────────────────────────────────────
  pw.Widget _sectionTitle(String title, pw.Font font, pw.Font bold) =>
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _green,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.white),
          textAlign: pw.TextAlign.right),
    );

  // ────────────────────────────────────────────────
  //  CREDIT BLOCK
  // ────────────────────────────────────────────────
  pw.Widget _creditBlock(
    Credit credit,
    List<Paiement> paiements,
    pw.Font font,
    pw.Font bold,
  ) {
    final isSolde     = credit.estSolde;
    final statusColor = isSolde ? PdfColors.green700 : PdfColors.red700;
    final statusText  = isSolde ? 'مسوى ✓' : 'جاري ●';
    final pct         = (credit.pourcentagePaye * 100).toStringAsFixed(0);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // ── Credit header ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: isSolde
                  ? const PdfColor.fromInt(0xFFE8F5E9)
                  : const PdfColor.fromInt(0xFFFFEBEE),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Left: status + date
                pw.Row(children: [
                  pw.Text(statusText,
                      style: pw.TextStyle(font: bold, fontSize: 11,
                          color: statusColor)),
                  pw.SizedBox(width: 12),
                  pw.Text(formatDate(credit.dateCredit),
                      style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                ]),
                // Right: total amount
                pw.Text(formatMontant(credit.montantTotal),
                    style: pw.TextStyle(font: bold, fontSize: 15, color: PdfColors.black)),
              ],
            ),
          ),

          // ── Credit body ──
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Amount row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: restant
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(formatMontant(credit.montantRestant),
                          style: pw.TextStyle(font: bold, fontSize: 14,
                              color: PdfColors.red700)),
                      pw.Text('الباقي',
                          style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
                    ]),
                    // Right: paye
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text(formatMontant(credit.montantTotal - credit.montantRestant),
                          style: pw.TextStyle(font: bold, fontSize: 14,
                              color: PdfColors.green700)),
                      pw.Text('مدفوع',
                          style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
                    ]),
                  ],
                ),

                pw.SizedBox(height: 8),

                // Progress bar
                pw.Stack(
                  children: [
                    // Background
                    pw.Container(
                      width: double.infinity,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFFEBEE),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                    ),
                    // Filled
                    pw.Container(
                      width: (credit.pourcentagePaye.clamp(0.0, 1.0)) * 500,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: _green,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('$pct% مدفوع',
                    style: pw.TextStyle(font: font, fontSize: 9, color: _green),
                    textAlign: pw.TextAlign.right),

                // Description
                if (credit.description != null && credit.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: _bgGrey,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(credit.description!,
                        style: pw.TextStyle(font: font, fontSize: 10, color: _grey),
                        textAlign: pw.TextAlign.right),
                  ),
                ],

                // ── Payments list ──
                if (paiements.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('الدفعات (${paiements.length}):',
                      style: pw.TextStyle(font: bold, fontSize: 11, color: _grey),
                      textAlign: pw.TextAlign.right),
                  pw.SizedBox(height: 6),
                  ...paiements.map((p) => _paymentRow(p, font, bold)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  PAYMENT ROW
  // ────────────────────────────────────────────────
  pw.Widget _paymentRow(Paiement p, pw.Font font, pw.Font bold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF1F8E9),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Left: amount
          pw.Text(formatMontant(p.montant),
              style: pw.TextStyle(font: bold, fontSize: 12,
                  color: PdfColors.green800)),
          // Middle: note
          pw.Expanded(
            child: pw.Text(p.note ?? '',
                style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
                textAlign: pw.TextAlign.center,
                maxLines: 1),
          ),
          // Right: date
          pw.Text(formatDate(p.datePaiement),
              style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  QUICK SUMMARY (one page — for sharing)
  // ────────────────────────────────────────────────
  Future<void> printClientSummary(Client client, double solde) async {
    final font     = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('كارنيه',
              style: pw.TextStyle(font: fontBold, fontSize: 28, color: _green)),
          pw.SizedBox(height: 4),
          pw.Text('ملخص العميل',
              style: pw.TextStyle(font: font, fontSize: 13, color: _grey)),
          pw.SizedBox(height: 24),
          pw.Divider(color: _green, thickness: 2),
          pw.SizedBox(height: 16),

          pw.Text(client.nom,
              style: pw.TextStyle(font: fontBold, fontSize: 22),
              textAlign: pw.TextAlign.center),

          if (client.telephone != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(client.telephone!,
                style: pw.TextStyle(font: font, fontSize: 14, color: _grey),
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
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(children: [
              pw.Text('الرصيد',
                  style: pw.TextStyle(font: font, fontSize: 12, color: _grey)),
              pw.SizedBox(height: 6),
              pw.Text(formatMontant(solde),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 28,
                    color: solde > 0
                        ? PdfColors.red700
                        : PdfColors.green700,
                  ),
                  textAlign: pw.TextAlign.center),
            ]),
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'تاريخ الإصدار: ${formatDate(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'تم الإنشاء بتطبيق كارنيه',
            style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}

