// lib/utils/helpers.dart
import 'package:intl/intl.dart';
import 'app_translations.dart';

String formatMontant(double m) {
  final fmt = NumberFormat('#,##0.00', 'fr_MA');
  final currency = Tr.s('currency');
  final number = fmt.format(m);

  // في العربية — نحطو العملة على اليمين مع LRM باش ما يتعكسش
  if (Tr.currentLang == 'ar') {
    // \u200E = Left-to-Right Mark — يمنع عكس الأرقام
    return '\u200E$number \u200E$currency';
  }

  return '$number $currency';
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';