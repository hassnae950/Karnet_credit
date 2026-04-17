import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0.00', 'fr_MA');

String formatMontant(double m) => '${_fmt.format(m)} درهم';

String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';