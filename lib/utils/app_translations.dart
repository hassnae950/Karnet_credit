// lib/utils/app_translations.dart
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class Tr {
  static String _lang = 'ar';

  static void setLang(String lang) => _lang = lang;
  static String get currentLang => _lang;

  // Convert lang code → Flutter Locale
  static Locale get locale {
    switch (_lang) {
      case 'fr':
        return const Locale('fr', 'FR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ar', 'MA');
    }
  }

  // ── Translation table ──────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _t = {

    // ── App / Navigation ──────────────────────────────────────────────────────
    'app_title':        {'ar': 'كارنيه',         'fr': 'Karnet',           'en': 'Karnet'},
    'clients':          {'ar': 'الزبائن',         'fr': 'Clients',          'en': 'Clients'},
    'suppliers':        {'ar': 'الموردين',        'fr': 'Fournisseurs',     'en': 'Suppliers'},
    'settings':         {'ar': 'الإعدادات',       'fr': 'Paramètres',       'en': 'Settings'},
    'home':             {'ar': 'الرئيسية',        'fr': 'Accueil',          'en': 'Home'},

    // ── Home ─────────────────────────────────────────────────────────────────
    'add_client':       {'ar': 'إضافة عميل',      'fr': 'Ajouter client',   'en': 'Add client'},
    'add_supplier':     {'ar': 'إضافة مورد',      'fr': 'Ajouter fournisseur','en': 'Add supplier'},
    // General notifications key already exists below in general section, 
    // but specific ones might need adding here if distinct.

    // ── Client list ───────────────────────────────────────────────────────────
    'search':           {'ar': 'البحث...',        'fr': 'Rechercher...',    'en': 'Search...'},
    'filter':           {'ar': 'تصفية',           'fr': 'Filtrer',          'en': 'Filter'},
    'took':             {'ar': 'أخذت',            'fr': 'Pris',             'en': 'Took'},
    'gave':             {'ar': 'أعطيت',           'fr': 'Donné',            'en': 'Gave'},
    'remaining':        {'ar': 'الباقي',          'fr': 'Restant',          'en': 'Remaining'},
    'settled':          {'ar': 'مسوى',            'fr': 'Soldé',            'en': 'Settled'},
    'no_clients':       {'ar': 'ما كاين حتى عملاء','fr': 'Aucun client',   'en': 'No clients'},
    'no_suppliers':     {'ar': 'ما كاين حتى موردين','fr': 'Aucun fournisseur','en': 'No suppliers'},
    'client_count':     {'ar': 'عميل',            'fr': 'client',           'en': 'client'},
    'supplier_count':   {'ar': 'مورد',            'fr': 'fournisseur',      'en': 'supplier'},
    'add_first_client': {'ar': 'ضغط على + باش تضيف عميل جديد',
                         'fr': 'Appuyez sur + pour ajouter un client',
                         'en': 'Tap + to add a new client'},
    'add_first_supplier':{'ar': 'ضغط على + باش تضيف مورد جديد',
                          'fr': 'Appuyez sur + pour ajouter un fournisseur',
                          'en': 'Tap + to add a new supplier'},

    // ── Stats labels ─────────────────────────────────────────────────────────
    'total_credit':     {'ar': 'إجمالي الكريدي', 'fr': 'Total crédits',    'en': 'Total credit'},
    'total_remaining':  {'ar': 'إجمالي الباقي',  'fr': 'Total restant',    'en': 'Total remaining'},
    'total_paid':       {'ar': 'إجمالي المدفوع', 'fr': 'Total payé',       'en': 'Total paid'},
    'total_balance':    {'ar': 'الرصيد الإجمالي','fr': 'Solde total',      'en': 'Total balance'},

    // ── Client detail ─────────────────────────────────────────────────────────
    'balance':          {'ar': 'الرصيد',          'fr': 'Solde',            'en': 'Balance'},
    // copy, call keys already in general section below

    'transactions':     {'ar': 'معاملات',         'fr': 'Transactions',     'en': 'Transactions'},
    'cheques':          {'ar': 'الشيكات',         'fr': 'Chèques',          'en': 'Cheques'},
    'no_transactions':  {'ar': 'ما كاين حتى معاملة','fr': 'Aucune transaction','en': 'No transactions'},
    'today':            {'ar': 'اليوم ساعة',      'fr': "Aujourd'hui à",    'en': 'Today at'},
    'note_placeholder': {'ar': 'أضف ملاحظة عن هذا العميل...',
                         'fr': 'Ajouter une note sur ce client...',
                         'en': 'Add a note about this client...'},
    'note_saved':       {'ar': 'تم حفظ الملاحظة ✅','fr': 'Note sauvegardée ✅','en': 'Note saved ✅'},
    'no_phone':         {'ar': 'ما كاين حتى رقم هاتف','fr': 'Aucun numéro de téléphone','en': 'No phone number'},
    'no_transactions_print':{'ar': 'ما كاين حتى معاملة للطباعة',
                             'fr': 'Aucune transaction à imprimer',
                             'en': 'No transactions to print'},
    'zero_balance_pay': {'ar': 'الرصيد صفر، ما كاين شي باش تخلصو',
                         'fr': 'Solde zéro, rien à payer',
                         'en': 'Balance is zero, nothing to pay'},
    // info_copied key already in general section below
    'add_cheque_label': {'ar': 'إضافة شيك',       'fr': 'Ajouter chèque',   'en': 'Add cheque'},
    'due_label':        {'ar': 'استحقاق:',        'fr': 'Échéance:',         'en': 'Due:'},
    'total_label':      {'ar': 'المجموع',         'fr': 'Total',            'en': 'Total'},
    'paid_label':       {'ar': 'مدفوع',           'fr': 'Payé',             'en': 'Paid'},
    'payment_history':  {'ar': 'سجل الدفعات',     'fr': 'Historique paiements','en': 'Payment history'},
    'no_payments':      {'ar': 'ما كاين حتى دفعة','fr': 'Aucun paiement',  'en': 'No payments'},


    // ── Add credit sheet ──────────────────────────────────────────────────────
    'add_credit':       {'ar': 'إضافة كريدي',    'fr': 'Ajouter crédit',   'en': 'Add credit'},
    // amount key already in general section below
    'description':      {'ar': 'الوصف (اختياري)','fr': 'Description (optionnel)','en': 'Description (optional)'},
    'gallery':          {'ar': 'معرض الصور',      'fr': 'Galerie',          'en': 'Gallery'},
    'camera':           {'ar': 'كاميرا',          'fr': 'Caméra',           'en': 'Camera'},
    'register_credit':  {'ar': 'تسجيل الكريدي',  'fr': 'Enregistrer crédit','en': 'Register credit'},
    'enter_valid_amount':{'ar': 'دخل مبلغ صحيح', 'fr': 'Entrez un montant valide','en': 'Enter a valid amount'},
    'currency':         {'ar': 'درهم',            'fr': 'MAD',              'en': 'MAD'},
'print':    {'ar': 'طباعة', 'fr': 'Imprimer', 'en': 'Print'},
'report':   {'ar': 'تقرير', 'fr': 'Rapport',  'en': 'Report'},

    // ── Add payment sheet ─────────────────────────────────────────────────────
    'add_payment':      {'ar': 'تسجيل دفعة',     'fr': 'Enregistrer paiement','en': 'Register payment'},
    'remaining_amount': {'ar': 'المبلغ المتبقي:','fr': 'Montant restant:',  'en': 'Remaining amount:'},
    'pay_all':          {'ar': 'خلص الكل',        'fr': 'Tout payer',       'en': 'Pay all'},
    'confirm_payment':  {'ar': 'تأكيد الدفعة',   'fr': 'Confirmer paiement','en': 'Confirm payment'},
    'note_optional':    {'ar': 'ملاحظة (اختياري)','fr': 'Note (optionnel)', 'en': 'Note (optional)'},
    'zero_balance':     {'ar': 'الرصيد صفر، ما كاين شي باش تخلصو',
                         'fr': 'Solde zéro',
                         'en': 'Balance is zero'},
    'amount_exceeds':   {'ar': 'المبلغ أكبر من الرصيد',
                         'fr': 'Montant supérieur au solde',
                         'en': 'Amount exceeds balance'},
    'payment_saved':    {'ar': 'تم تسجيل دفعة',  'fr': 'Paiement enregistré','en': 'Payment saved'},
    'payment_saved_amount':{'ar': 'تم تسجيل دفعة',
                            'fr': 'Paiement enregistré:',
                            'en': 'Payment saved:'},

    // ── Add client sheet ──────────────────────────────────────────────────────
    'add_new_client':   {'ar': 'إضافة عميل جديد','fr': 'Nouveau client',   'en': 'New client'},
    'add_new_supplier': {'ar': 'إضافة مورد جديد','fr': 'Nouveau fournisseur','en': 'New supplier'},
    'client':           {'ar': 'زبون',            'fr': 'Client',           'en': 'Client'},
    'supplier':         {'ar': 'مورد',            'fr': 'Fournisseur',      'en': 'Supplier'},
    'name_required_label': {'ar': 'الاسم *',      'fr': 'Nom *',            'en': 'Name *'}, // Changed from 'name' to avoid conflict with login sections
    'company':          {'ar': 'اسم الشركة (اختياري)','fr': 'Société (optionnel)','en': 'Company (optional)'},
    'address':          {'ar': 'العنوان (اختياري)','fr': 'Adresse (optionnel)','en': 'Address (optional)'},
    'notes_optional':   {'ar': 'ملاحظات (اختياري)','fr': 'Notes (optionnel)','en': 'Notes (optional)'},
    'choose_category':  {'ar': 'اختر التصنيف',   'fr': 'Choisir catégorie','en': 'Choose category'},
    'no_category':      {'ar': 'بدون تصنيف',      'fr': 'Sans catégorie',   'en': 'No category'},
    'name_is_required': {'ar': 'الاسم مطلوب',    'fr': 'Nom requis',       'en': 'Name required'}, // Changed from 'name_required' to avoid conflict

    // ── Edit client ───────────────────────────────────────────────────────────
    'edit_client':      {'ar': 'تعديل العميل',   'fr': 'Modifier client',  'en': 'Edit client'},
    'edit_supplier':    {'ar': 'تعديل المورد',   'fr': 'Modifier fournisseur','en': 'Edit supplier'},
    'client_type':      {'ar': 'نوع الحساب',     'fr': 'Type de compte',   'en': 'Account type'},

    // ── Transaction detail ────────────────────────────────────────────────────
    'took_label':       {'ar': 'أخذت',            'fr': 'Pris',             'en': 'Took'},
    'gave_label':       {'ar': 'أعطيت',           'fr': 'Donné',            'en': 'Gave'},
    'recorded':         {'ar': 'مسجلة',           'fr': 'Enregistré',       'en': 'Recorded'},
    'delete_tx':        {'ar': 'حذف المعاملة',   'fr': 'Supprimer transaction','en': 'Delete transaction'},
    'confirm_delete_tx':{'ar': 'واش متأكد من حذف هاد المعاملة؟',
                         'fr': 'Supprimer cette transaction?',
                         'en': 'Delete this transaction?'},
    // edited key in generic section below
    'edit_credit':      {'ar': 'تعديل الكريدي',  'fr': 'Modifier crédit',  'en': 'Edit credit'},
    'edit_payment':     {'ar': 'تعديل الدفعة',   'fr': 'Modifier paiement','en': 'Edit payment'},
    // save_edit key in generic section below
    'credit_label':     {'ar': 'كريدي',           'fr': 'Crédit',           'en': 'Credit'},
    'payment_label':    {'ar': 'دفعة',            'fr': 'Paiement',         'en': 'Payment'},
    'cheque_notif_label':{'ar': 'شيك',            'fr': 'Chèque',           'en': 'Cheque'}, // distinguish from other cheque labels
    // date_label, amount_label generic keys already below

    // ── Settings ──────────────────────────────────────────────────────────────
    'appearance':       {'ar': 'المظهر',          'fr': 'Apparence',        'en': 'Appearance'},
    'light':            {'ar': 'فاتح ☀️',         'fr': 'Clair ☀️',         'en': 'Light ☀️'},
    'dark':             {'ar': 'داكن 🌙',         'fr': 'Sombre 🌙',        'en': 'Dark 🌙'},
    'system':           {'ar': 'تلقائي 📱',       'fr': 'Système 📱',       'en': 'System 📱'},
    'backup':           {'ar': 'النسخ الاحتياطي', 'fr': 'Sauvegarde',       'en': 'Backup'},
    'export_data':      {'ar': 'تصدير البيانات',  'fr': 'Exporter données', 'en': 'Export data'},
    'export_desc':      {'ar': 'حفظ نسخة احتياطية JSON',
                         'fr': 'Sauvegarder en JSON',
                         'en': 'Save JSON backup'},
    // language key already below in general labels
    'delete_all':       {'ar': 'حذف كل البيانات','fr': 'Supprimer toutes les données','en': 'Delete all data'},
    'delete_all_desc':  {'ar': 'سيتم حذف جميع العملاء والمعاملات',
                         'fr': 'Tous les clients et transactions seront supprimés',
                         'en': 'All clients and transactions will be deleted'},
    'delete_all_confirm':{'ar': 'غادي يتمحاو جميع العملاء والمعاملات بلا رجعة. متأكد 100%؟',
                          'fr': 'Toutes les données seront supprimées définitivement. Confirmer?',
                          'en': 'All data will be permanently deleted. Confirm?'},
    'delete_all_btn':   {'ar': 'حذف الكل',        'fr': 'Tout supprimer',   'en': 'Delete all'},
    'data_deleted':     {'ar': 'تم حذف كل البيانات','fr': 'Données supprimées','en': 'All data deleted'},
    'backup_saved':     {'ar': 'تم حفظ النسخة ✅ — مسار الملف تم نسخه',
                         'fr': 'Sauvegarde enregistrée ✅ — Chemin copié',
                         'en': 'Backup saved ✅ — Path copied'},
    // about generic key already below
    'app_name_field':   {'ar': 'اسم التطبيق',    'fr': "Nom de l'app",     'en': 'App name'}, // renamed generic label
    'version':          {'ar': 'الإصدار',         'fr': 'Version',          'en': 'Version'},
    'system_auto':      {'ar': 'تلقائي حسب النظام 📱',
                         'fr': 'Automatique selon le système 📱',
                         'en': 'Automatic (system) 📱'},

    // ── Delete client ─────────────────────────────────────────────────────────
    'delete_client':    {'ar': 'حذف العميل',      'fr': 'Supprimer client', 'en': 'Delete client'},
    'delete_supplier':  {'ar': 'حذف المورد',      'fr': 'Supprimer fournisseur','en': 'Delete supplier'},
    'confirm_delete_client':{'ar': 'هل أنت متأكد من الحذف؟',
                             'fr': 'Confirmer la suppression?',
                             'en': 'Confirm deletion?'},
    'confirm_delete_msg':{'ar': 'هل أنت متأكد من حذف',
                          'fr': 'Êtes-vous sûr de supprimer',
                          'en': 'Are you sure you want to delete'},
    'delete_warning':   {'ar': 'سيتم حذف جميع بياناته',
                         'fr': 'Toutes ses données seront supprimées',
                         'en': 'All associated data will be deleted'},

    // ── Cheque ────────────────────────────────────────────────────────────────
    'add_cheque':       {'ar': 'إضافة شيك',       'fr': 'Ajouter chèque',  'en': 'Add cheque'},
    'cheque_number':    {'ar': 'رقم الشيك *',     'fr': 'N° chèque *',     'en': 'Cheque No. *'},
    'cheque_number_required':{'ar': 'رقم الشيك مطلوب',
                              'fr': 'Numéro de chèque requis',
                              'en': 'Cheque number required'},
    'bank':             {'ar': 'البنك (اختياري)', 'fr': 'Banque (optionnel)','en': 'Bank (optional)'},
    'due_date':         {'ar': 'تاريخ الاستحقاق *','fr': "Date d'échéance *",'en': 'Due date *'},
    'due_date_required':{'ar': 'تاريخ الاستحقاق مطلوب',
                         'fr': "Date d'échéance requise",
                         'en': 'Due date required'},
    'save_cheque':      {'ar': 'حفظ الشيك',       'fr': 'Enregistrer chèque','en': 'Save cheque'},
    'waiting':          {'ar': 'قيد الانتظار',    'fr': 'En attente',       'en': 'Pending'},
    'collected':        {'ar': 'محصّل',            'fr': 'Encaissé',         'en': 'Collected'},
    'rejected':         {'ar': 'مرفوض',           'fr': 'Refusé',           'en': 'Rejected'},
    // due key generic below
    'no_cheques':       {'ar': 'ما كاين حتى شيك', 'fr': 'Aucun chèque',    'en': 'No cheques'},
    'cheque_prefix':    {'ar': 'شيك #',           'fr': 'Chèque #',         'en': 'Cheque #'},
    'cheque_status':    {'ar': 'حالة الشيك',      'fr': 'Statut du chèque','en': 'Cheque status'},
    'mark_collected':   {'ar': 'تحصيل',           'fr': 'Encaisser',        'en': 'Collect'},
    'mark_rejected':    {'ar': 'رفض',             'fr': 'Refuser',          'en': 'Reject'},
    'mark_pending':     {'ar': 'إعادة للانتظار',  'fr': 'Remettre en attente','en': 'Set pending'},

    // ── Client settings screen ────────────────────────────────────────────────
    'client_settings':  {'ar': 'إعدادات',         'fr': 'Paramètres',       'en': 'Settings'},
    'client_notif':     {'ar': 'إشعارات',         'fr': 'Notifications',    'en': 'Notifications'},
    'cheque_notif_title': {'ar': 'إشعارات الشيكات',
                       'fr': 'Notifications chèques',
                       'en': 'Cheque notifications'},
'cheque_notif_desc':  {'ar': 'تنبيه عند قرب استحقاق شيك',
                       'fr': 'Alerte avant échéance de chèque',
                       'en': 'Alert before cheque due date'},
'notif_enabled':      {'ar': '✅ تم تفعيل الإشعارات',
                       'fr': '✅ Notifications activées',
                       'en': '✅ Notifications enabled'},
'notif_disabled':     {'ar': '🔕 تم إيقاف الإشعارات',
                       'fr': '🔕 Notifications désactivées',
                       'en': '🔕 Notifications disabled'},
'app_name':           {'ar': 'كارنيه', 'fr': 'Karnet', 'en': 'Karnet'},
    'client_notif_desc':{'ar': 'تنبيه عند قرب استحقاق شيك',
                         'fr': 'Alerte avant échéance de chèque',
                         'en': 'Alert before cheque due date'},
    'confirm_delete_label':{'ar': 'تأكيد الحذف', 'fr': 'Confirmer la suppression','en': 'Confirm deletion'},

    // ── PDF / Report ──────────────────────────────────────────────────────────
    'pdf_report':       {'ar': 'تقرير PDF',       'fr': 'Rapport PDF',      'en': 'PDF Report'},
    'generating_report':{'ar': 'جاري إنشاء التقرير...','fr': 'Génération du rapport...','en': 'Generating report...'},
    'report_ready':     {'ar': 'التقرير جاهز',   'fr': 'Rapport prêt',     'en': 'Report ready'},

    // ── Months ────────────────────────────────────────────────────────────────
    'jan': {'ar': 'يناير',    'fr': 'Janvier',    'en': 'January'},
    'feb': {'ar': 'فبراير',   'fr': 'Février',    'en': 'February'},
    'mar': {'ar': 'مارس',     'fr': 'Mars',       'en': 'March'},
    'apr': {'ar': 'أبريل',    'fr': 'Avril',      'en': 'April'},
    'may': {'ar': 'مايو',     'fr': 'Mai',        'en': 'May'},
    'jun': {'ar': 'يونيو',    'fr': 'Juin',       'en': 'June'},
    'jul': {'ar': 'يوليو',    'fr': 'Juillet',    'en': 'July'},
    'aug': {'ar': 'أغسطس',    'fr': 'Août',       'en': 'August'},
    'sep': {'ar': 'سبتمبر',   'fr': 'Septembre',  'en': 'September'},
    'oct': {'ar': 'أكتوبر',   'fr': 'Octobre',    'en': 'October'},
    'nov': {'ar': 'نوفمبر',   'fr': 'Novembre',   'en': 'November'},
    'dec': {'ar': 'ديسمبر',   'fr': 'Décembre',   'en': 'December'},

    // ── Days ─────────────────────────────────────────────────────────────────
    'mon': {'ar': 'الاثنين',  'fr': 'Lundi',      'en': 'Monday'},
    'tue': {'ar': 'الثلاثاء', 'fr': 'Mardi',      'en': 'Tuesday'},
    'wed': {'ar': 'الأربعاء', 'fr': 'Mercredi',   'en': 'Wednesday'},
    'thu': {'ar': 'الخميس',   'fr': 'Jeudi',      'en': 'Thursday'},
    'fri': {'ar': 'الجمعة',   'fr': 'Vendredi',   'en': 'Friday'},
    'sat': {'ar': 'السبت',    'fr': 'Samedi',     'en': 'Saturday'},
    'sun': {'ar': 'الأحد',    'fr': 'Dimanche',   'en': 'Sunday'},


    // ✅ New merged translations starting here:

    // ── دخول (Login) ──────────────────────────────────────────────────
    // app_title defined above, app_description added
    'app_description':  {'ar': 'تسيير الكريديات بسهولة', 'fr': 'Gestion facile des crédits', 'en': 'Easy Credit Management'},
    'phone_required':   {'ar': 'رقم الهاتف مطلوب', 'fr': 'Le numéro de téléphone est requis', 'en': 'Phone number is required'},
    'login_with_phone': {'ar': 'الدخول برقم الهاتف', 'fr': 'Connectez-vous avec le téléphone', 'en': 'Login with Phone'},
    'login_description':{'ar': 'أدخل رقم الهاتف للدخول أو إنشاء حساب جديد',
                         'fr': 'Entrez votre numéro de téléphone pour vous connecter ou créer un compte',
                         'en': 'Enter your phone number to login or create an account'},
    'enter_phone_hint': {'ar': '+212 6 12 34 56 78', 'fr': '+33 6 12 34 56 78', 'en': '+1 (555) 123-4567'},
    'login':            {'ar': 'الدخول', 'fr': 'Connexion', 'en': 'Login'},
    'or':               {'ar': 'أو', 'fr': 'Ou', 'en': 'Or'},
    'create_account_title':{'ar': 'إنشاء حساب جديد', 'fr': 'Créer un nouveau compte', 'en': 'Create New Account'}, // renamed to distinguish

    // ── التسجيل (Sign Up) ─────────────────────────────────────────────
    'signup_title':     {'ar': 'إنشاء حساب جديد', 'fr': 'Créer un nouveau compte', 'en': 'Create New Account'},
    'signup_description':{'ar': 'أنشئ حساباً آمناً لتسيير كريديتاتك بكل سهولة',
                         'fr': 'Créez un compte sécurisé pour gérer facilement vos crédits',
                         'en': 'Create a secure account to manage your credits easily'},
    'username':         {'ar': 'اسم المستخدم', 'fr': "Nom d'utilisateur", 'en': 'Username'},
    'username_hint':    {'ar': 'اختر اسم فريد', 'fr': 'Choisissez un nom unique', 'en': 'Choose a unique name'},
    'username_required':{'ar': 'اسم المستخدم مطلوب', 'fr': "Le nom d'utilisateur est requis", 'en': 'Username is required'},
    'username_short':   {'ar': 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل',
                         'fr': "Le nom d'utilisateur doit contenir au moins 3 caractères",
                         'en': 'Username must be at least 3 characters'},
    'username_exists':  {'ar': 'اسم المستخدم مستخدم بالفعل', 'fr': "Le nom d'utilisateur est déjà utilisé", 'en': 'Username is already taken'},
    'password':         {'ar': 'كلمة المرور', 'fr': 'Mot de passe', 'en': 'Password'},
    'password_hint':    {'ar': 'كلمة مرور قوية', 'fr': 'Mot de passe fort', 'en': 'Strong password'},
    'password_required':{'ar': 'كلمة المرور مطلوبة', 'fr': 'Le mot de passe est requis', 'en': 'Password is required'},
    'password_weak':    {'ar': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                         'fr': 'Le mot de passe doit contenir au moins 6 caractères',
                         'en': 'Password must be at least 6 characters'},
    'password_strength':{'ar': 'قوة كلمة المرور:', 'fr': 'Force du mot de passe:', 'en': 'Password Strength:'},
    'password_min_length':{'ar': '6 أحرف على الأقل', 'fr': 'Au moins 6 caractères', 'en': 'At least 6 characters'},
    'password_has_numbers':{'ar': 'تحتوي على أرقام', 'fr': 'Contient des chiffres', 'en': 'Contains numbers'},
    'password_has_uppercase':{'ar': 'تحتوي على أحرف كبيرة', 'fr': 'Contient des lettres majuscules', 'en': 'Contains uppercase letters'},
    'password_has_special':{'ar': 'تحتوي على رموز خاصة', 'fr': 'Contient des symboles spéciaux', 'en': 'Contains special symbols'},
    'confirm_password': {'ar': 'تأكيد كلمة المرور', 'fr': 'Confirmer le mot de passe', 'en': 'Confirm Password'},
    'confirm_password_hint':{'ar': 'أعد كتابة كلمة المرور', 'fr': 'Réentrez votre mot de passe', 'en': 'Re-enter your password'},
    'confirm_password_required':{'ar': 'تأكيد كلمة المرور مطلوب', 'fr': 'La confirmation du mot de passe est requise', 'en': 'Confirm password is required'},
    'passwords_mismatch':{'ar': 'كلمتا المرور غير متطابقة', 'fr': 'Les mots de passe ne correspondent pas', 'en': 'Passwords do not match'},
    // phone generic below
    'phone_optional_hint':{'ar': 'رقم الهاتف (اختياري)', 'fr': 'Téléphone (optionnel)', 'en': 'Phone (optional)'},
    'phone_invalid_msg':{'ar': 'رقم الهاتف غير صحيح', 'fr': 'Numéro de téléphone invalide', 'en': 'Invalid phone number'},
    'signup_button':    {'ar': 'إنشاء الحساب', 'fr': 'Créer un compte', 'en': 'Create Account'},
    'have_account':     {'ar': 'لديك حساب بالفعل؟', 'fr': 'Vous avez déjà un compte?', 'en': 'Already have an account?'},
    'sign_in_link':     {'ar': 'تسجيل دخول', 'fr': 'Se connecter', 'en': 'Sign In'},
    'signup_success':   {'ar': 'تم إنشاء الحساب بنجاح', 'fr': 'Compte créé avec succès', 'en': 'Account created successfully'},
    'signup_error_msg': {'ar': 'خطأ في التسجيل', 'fr': "Erreur d'inscription", 'en': 'Sign up error'},

    // ── تسجيل الخروج (Logout) ────────────────────────────────────────
    'logout':           {'ar': 'تسجيل الخروج', 'fr': 'Déconnexion', 'en': 'Logout'},
    'logout_confirm':   {'ar': 'هل تريد تسجيل الخروج من التطبيق؟',
                         'fr': "Voulez-vous vous déconnecter de l'application?",
                         'en': 'Do you want to logout from the app?'},
    'logout_success_msg':{'ar': 'تم تسجيل الخروج بنجاح', 'fr': 'Déconnexion réussie', 'en': 'Logged out successfully'},

    // ── رسائل عامة (General Messages/Labels) ─────────────────────────
    // Existing generic keys mapped to new requests where appropriate
    'error':            {'ar': 'خطأ', 'fr': 'Erreur', 'en': 'Error'},
    'error_prefix':     {'ar': 'خطأ:', 'fr': 'Erreur:', 'en': 'Error:'},
    'success':          {'ar': 'نجاح', 'fr': 'Succès', 'en': 'Success'},
    'loading':          {'ar': 'جاري التحميل...', 'fr': 'Chargement...', 'en': 'Loading...'},
    'cancel':           {'ar': 'إلغاء', 'fr': 'Annuler', 'en': 'Cancel'},
    'confirm':          {'ar': 'تأكيد', 'fr': 'Confirmer', 'en': 'Confirm'},
    'ok':               {'ar': 'حسناً', 'fr': 'OK', 'en': 'OK'},
    'yes':              {'ar': 'نعم', 'fr': 'Oui', 'en': 'Yes'},
    'no':               {'ar': 'لا', 'fr': 'Non', 'en': 'No'},
    'close':            {'ar': 'إغلاق', 'fr': 'Fermer', 'en': 'Close'},
    'save':             {'ar': 'حفظ', 'fr': 'Enregistrer', 'en': 'Save'},
    'delete':           {'ar': 'حذف', 'fr': 'Supprimer', 'en': 'Delete'},
    'edit':             {'ar': 'تعديل', 'fr': 'Modifier', 'en': 'Edit'},
    'done':             {'ar': 'تم', 'fr': 'Fait', 'en': 'Done'},
    'copy':             {'ar': 'نسخ', 'fr': 'Copier', 'en': 'Copy'}, // existing
    'note':             {'ar': 'ملاحظة', 'fr': 'Note', 'en': 'Note'}, // existing
    'notes_label':      {'ar': 'ملاحظات', 'fr': 'Notes', 'en': 'Notes'}, // distinguish
    'phone':            {'ar': 'رقم الهاتف', 'fr': 'Téléphone', 'en': 'Phone'}, // added specific name key above
    'address_label':    {'ar': 'العنوان', 'fr': 'Adresse', 'en': 'Address'}, // distinguish
    'gallery_label':    {'ar': 'معرض الصور', 'fr': 'Galerie', 'en': 'Gallery'}, // existing
    'camera_label':     {'ar': 'كاميرا', 'fr': 'Caméra', 'en': 'Camera'}, // existing
    'date_label':       {'ar': 'التاريخ', 'fr': 'Date', 'en': 'Date'}, // existing
    'edited':           {'ar': 'تم التعديل', 'fr': 'Modifié', 'en': 'Edited'}, // existing
    'save_edit':        {'ar': 'حفظ التعديل', 'fr': 'Sauvegarder', 'en': 'Save edit'}, // existing
    'language':         {'ar': 'اللغة', 'fr': 'Langue', 'en': 'Language'}, // existing
    'system_auto_label':{'ar': 'تلقائي حسب النظام 📱', 'fr': 'Automatique (système) 📱', 'en': 'Automatic (system) 📱'}, // existing

    // ── رسائل الخطأ (Error Messages) ─────────────────────────────────
    'invalid_input':    {'ar': 'إدخال غير صحيح', 'fr': 'Saisie invalide', 'en': 'Invalid input'},
    'network_error':    {'ar': 'خطأ في الاتصال', 'fr': 'Erreur de connexion', 'en': 'Network error'},
    'try_again':        {'ar': 'حاول مجدداً', 'fr': 'Réessayer', 'en': 'Try again'},
    'something_wrong':  {'ar': 'حدث خطأ ما', 'fr': 'Quelque chose a mal tourné', 'en': 'Something went wrong'},
    'enter_valid_amount_err':{'ar': 'دخل مبلغ صحيح', 'fr': 'Entrez un montant valide', 'en': 'Enter a valid amount'}, // existing
    'amount_exceeds_err':{'ar': 'المبلغ أكبر من الرصيد', 'fr': 'Montant supérieur au solde', 'en': 'Amount exceeds balance'}, // existing
    'name_required_err':{'ar': 'الاسم مطلوب', 'fr': 'Nom requis', 'en': 'Name required'}, // generic err
    'cheque_number_required_err':{'ar': 'رقم الشيك مطلوب', 'fr': 'Numéro de chèque requis', 'en': 'Cheque number required'}, // generic err
    'due_date_required_err':{'ar': 'تاريخ الاستحقاق مطلوب', 'fr': "Date d'échéance requise", 'en': 'Due date required'}, // generic err
    'error_save_generic':{'ar': 'خطأ في الحفظ', 'fr': 'Erreur de sauvegarde', 'en': 'Save error'}, // existing
    'error_delete_generic':{'ar': 'خطأ في الحذف', 'fr': 'Erreur de suppression', 'en': 'Delete error'}, // existing
    'error_generic_msg':{'ar': 'حدث خطأ', 'fr': 'Une erreur est survenue', 'en': 'An error occurred'}, // existing

    // ── أيقونات/تسميات (Icons/Labels - for settings/menus) ───────────────────────────────
    'user':             {'ar': 'مستخدم', 'fr': 'Utilisateur', 'en': 'User'},
    'account':          {'ar': 'الحساب', 'fr': 'Compte', 'en': 'Account'},
    'notifications_label':{'ar': 'الإشعارات', 'fr': 'Notifications', 'en': 'Notifications'}, // distuinguish from home key
    'help':             {'ar': 'المساعدة', 'fr': 'Aide', 'en': 'Help'},
    'about_label':      {'ar': 'عن التطبيق', 'fr': 'À propos', 'en': 'About'}, // distinguish generic key
    'appearance_label': {'ar': 'المظهر', 'fr': 'Apparence', 'en': 'Appearance'}, // existing
    'backup_label':     {'ar': 'النسخ الاحتياطي', 'fr': 'Sauvegarde', 'en': 'Backup'}, // existing
    'delete_all_label': {'ar': 'حذف كل البيانات', 'fr': 'Supprimer toutes les données', 'en': 'Delete all data'}, // distuinguish from btn key
    'cheque_status_label':{'ar': 'حالة الشيك', 'fr': 'Statut du chèque', 'en': 'Cheque status'}, // distuinguish from history key
  
  // ═══════════════════════════════════════════════════════════════════
// BLOC À COPIER dans app_translations.dart
// Collez ces clés AVANT la dernière accolade }; de _t
// ═══════════════════════════════════════════════════════════════════

// ── Clients screen — tri et filtre ──────────────────────────────────
'sort_filter_title': {'ar': 'ترتيب وفلتر',        'fr': 'Trier et filtrer',      'en': 'Sort & filter'},
'sort_label':        {'ar': 'الترتيب',             'fr': 'Trier par',             'en': 'Sort by'},
'filter_label':      {'ar': 'الفلتر',              'fr': 'Filtrer par',           'en': 'Filter by'},
'sort_recent':       {'ar': '⚡ نشاط حديث',        'fr': '⚡ Activité récente',   'en': '⚡ Recent activity'},
'sort_debt_high':    {'ar': '💰 أكبر دين',         'fr': '💰 Plus grande dette',  'en': '💰 Highest debt'},
'sort_debt_low':     {'ar': '💸 أصغر دين',         'fr': '💸 Plus petite dette',  'en': '💸 Lowest debt'},
'sort_name_az':      {'ar': 'أ-ي اسم',             'fr': 'A-Z nom',               'en': 'A-Z name'},
'sort_name_za':      {'ar': 'ي-أ اسم',             'fr': 'Z-A nom',               'en': 'Z-A name'},
'sort_oldest':       {'ar': '📅 الأقدم',            'fr': '📅 Le plus ancien',     'en': '📅 Oldest'},
'filter_all':        {'ar': '📋 الكل',             'fr': '📋 Tous',               'en': '📋 All'},
'filter_with_debt':  {'ar': '🔴 عنده دين',         'fr': '🔴 Avec dette',         'en': '🔴 With debt'},
'filter_settled':    {'ar': '✅ مسوى',              'fr': '✅ Soldé',              'en': '✅ Settled'},
'filter_has_cheque': {'ar': '📄 عنده شيكات',       'fr': '📄 Avec chèques',       'en': '📄 Has cheques'},
'clear_filter':      {'ar': 'مسح الفلتر',          'fr': 'Effacer le filtre',     'en': 'Clear filter'},
'clear_all':         {'ar': 'مسح الكل',            'fr': 'Tout effacer',          'en': 'Clear all'},
'apply':             {'ar': 'تطبيق',               'fr': 'Appliquer',             'en': 'Apply'},
'no_results':        {'ar': 'ما كاين حتى نتيجة',   'fr': 'Aucun résultat',        'en': 'No results'},

// ── Notifications screen ─────────────────────────────────────────────
'notif_go_to_client':      {'ar': 'اضغط للذهاب للعميل',
                             'fr': 'Appuyez pour voir le client',
                             'en': 'Tap to view client'},
'notif_no_cheques_due':    {'ar': 'ما كاينش شيكات قريبة من الاستحقاق',
                             'fr': 'Aucun chèque bientôt dû',
                             'en': 'No cheques due soon'},
'notif_cheques_appear_here':{'ar': 'الشيكات اللي تستحق خلال 15 يوم كتظهر هنا',
                              'fr': 'Les chèques dus dans 15 jours apparaissent ici',
                              'en': 'Cheques due within 15 days appear here'},
'notif_overdue':           {'ar': 'فات الاستحقاق منذ',
                             'fr': 'Échu depuis',
                             'en': 'Overdue by'},
'notif_days_ago':          {'ar': 'يوم',            'fr': 'jour(s)',               'en': 'day(s)'},
'notif_due_today':         {'ar': '🔴 يستحق اليوم!','fr': '🔴 Dû aujourd\'hui !', 'en': '🔴 Due today!'},
'notif_due_tomorrow':      {'ar': '⚠️ يستحق غداً!', 'fr': '⚠️ Dû demain !',       'en': '⚠️ Due tomorrow!'},
'notif_due_in':            {'ar': 'يستحق بعد',      'fr': 'Dû dans',              'en': 'Due in'},
'notif_days':              {'ar': 'أيام',            'fr': 'jours',                'en': 'days'},
'notif_day':               {'ar': 'يوم',             'fr': 'jour',                 'en': 'day'},
 'backup_to_cloud': {
  'ar': '☁️ حفظ البيانات في السحابة',
  'fr': '☁️ Sauvegarder dans le cloud',
  'en': '☁️ Backup to cloud'
},

'backup_success': {
  'ar': '✅ تم حفظ البيانات بنجاح',
  'fr': '✅ Sauvegarde réussie',
  'en': '✅ Backup successful'
},

'restore_from_cloud': {
  'ar': '☁️ استعادة البيانات من السحابة',
  'fr': '☁️ Restaurer depuis le cloud',
  'en': '☁️ Restore from cloud'
},

'restore_success': {
  'ar': '✅ تم استعادة البيانات بنجاح',
  'fr': '✅ Restauration réussie',
  'en': '✅ Restore successful'
},

'no_internet_error': {
  'ar': '❌ لا يوجد اتصال بالإنترنت',
  'fr': '❌ Pas de connexion Internet',
  'en': '❌ No internet connection'
},

// ── Backup / Restore descriptions ────────────────────────────────────
'backup_to_cloud_desc': {
  'ar': 'رفع البيانات للسحابة',
  'fr': 'Envoyer les données au cloud',
  'en': 'Upload data to cloud'
},
'restore_from_cloud_desc': {
  'ar': 'استرجاع البيانات من السحابة',
  'fr': 'Récupérer les données du cloud',
  'en': 'Retrieve data from cloud'
},
'restore': {
  'ar': 'الاستعادة',
  'fr': 'Restauration',
  'en': 'Restore'
},
'error_permission_denied': {
  'ar': '❌ لا توجد صلاحية للوصول إلى السحابة',
  'fr': '❌ Permission refusée pour accéder au cloud',
  'en': '❌ Permission denied to access cloud'
},
'backup_in_progress': {
  'ar': 'جاري الحفظ في السحابة...',
  'fr': 'Sauvegarde en cours...',
  'en': 'Backing up to cloud...'
},
'restore_in_progress': {
  'ar': 'جاري الاستعادة من السحابة...',
  'fr': 'Restauration en cours...',
  'en': 'Restoring from cloud...'
},
'no_cloud_data': {
  'ar': 'ما كاين حتى بيانات فالسحابة',
  'fr': 'Aucune donnée dans le cloud',
  'en': 'No data found in cloud'
},

// أضف هذه المفاتيح الجديدة داخل الـ Map _t قبل الإغلاق الأخير

// ── Security / PIN screen ─────────────────────────────────────────────
'pin_security_title': {
  'ar': 'قفل التطبيق برمز سري',
  'fr': 'Verrouiller l\'application avec code PIN',
  'en': 'Lock app with PIN code'
},
'pin_security_subtitle': {
  'ar': 'طبقة أمان إضافية عند فتح التطبيق',
  'fr': 'Couche de sécurité supplémentaire lors de l\'ouverture de l\'application',
  'en': 'Additional security layer when opening the app'
},
'pin_enabled': {
  'ar': 'تم تفعيل قفل التطبيق',
  'fr': 'Verrouillage de l\'application activé',
  'en': 'App lock enabled'
},
'pin_disabled': {
  'ar': 'تم إيقاف قفل التطبيق',
  'fr': 'Verrouillage de l\'application désactivé',
  'en': 'App lock disabled'
},
'enter_pin': {
  'ar': 'أدخل الرمز السري',
  'fr': 'Entrez le code PIN',
  'en': 'Enter PIN code'
},
'verify_pin': {
  'ar': 'تحقق من الرمز السري',
  'fr': 'Vérifiez le code PIN',
  'en': 'Verify PIN code'
},
'wrong_pin': {
  'ar': 'الرمز السري غير صحيح',
  'fr': 'Code PIN incorrect',
  'en': 'Wrong PIN code'
},
'pin_required': {
  'ar': 'الرمز السري مطلوب',
  'fr': 'Code PIN requis',
  'en': 'PIN code required'
},

// أضف داخل الـ Map _t قبل الإغلاق الأخير:

// ── PIN / Security ──────────────────────────────────────────────────────
'disable_pin_title': {
  'ar': 'إيقاف قفل التطبيق',
  'fr': 'Désactiver le verrouillage de l\'application',
  'en': 'Disable app lock'
},
'disable_pin_confirm': {
  'ar': 'هل تريد إيقاف الرمز السري؟ سيتم حذفه نهائياً.',
  'fr': 'Voulez-vous désactiver le code PIN ? Il sera définitivement supprimé.',
  'en': 'Do you want to disable the PIN code? It will be permanently deleted.'
},
'disable': {
  'ar': 'إيقاف',
  'fr': 'Désactiver',
  'en': 'Disable'
},
// ── PIN setup ──────────────────────────────────────────────────────────
'choose_pin': {
  'ar': 'اختر رمزاً سرياً (4 أرقام)',
  'fr': 'Choisissez un code PIN (4 chiffres)',
  'en': 'Choose a PIN code (4 digits)'
},
'confirm_pin': {
  'ar': 'أكد الرمز السري',
  'fr': 'Confirmez le code PIN',
  'en': 'Confirm PIN code'
},
'pins_dont_match': {
  'ar': 'الرمزان غير متطابقان',
  'fr': 'Les codes PIN ne correspondent pas',
  'en': 'PIN codes do not match'
},
// أضف داخل الـ Map _t:

'add_transaction': {
  'ar': 'إضافة معاملة جديدة',
  'fr': 'Ajouter une transaction',
  'en': 'Add new transaction'
},
'select_client': {
  'ar': 'اختر العميل',
  'fr': 'Choisir le client',
  'en': 'Select client'
},
'select_client_error': {
  'ar': 'الرجاء اختيار عميل',
  'fr': 'Veuillez choisir un client',
  'en': 'Please select a client'
},
'cheque_transaction': {
  'ar': 'هذه المعاملة بشيك',
  'fr': 'Cette transaction est par chèque',
  'en': 'This transaction is by cheque'
},

'select_date': {
  'ar': 'اختر التاريخ',
  'fr': 'Choisir la date',
  'en': 'Select date'
},
'no_open_credit': {
  'ar': 'لا يوجد كريدي مفتوح لهذا العميل',
  'fr': 'Aucun crédit ouvert pour ce client',
  'en': 'No open credit for this client'
},
'register_payment': {
  'ar': 'تسجيل دفعة',
  'fr': 'Enregistrer le paiement',
  'en': 'Register payment'
},

  };

  // ── Core lookup ──────────────────────────────────────────────────────────────
  static String get(String key) =>
      _t[key]?[_lang] ?? _t[key]?['ar'] ?? key;

  /// Short alias — use like: Tr.s('save')
  static String s(String key) => get(key);

  // ── Date helpers ─────────────────────────────────────────────────────────────
  static String monthName(int month) {
    const keys = [
      '', 'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    if (month < 1 || month > 12) return '';
    return get(keys[month]);
  }

  /// Formats a transaction date: "اليوم ساعة 11:20" or "15 أبريل 09:30"
  static String formatTxDate(String isoDate) {
    final d = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);
    if (txDay == today) return '${get('today')} $h:$m';
    return '${d.day} ${monthName(d.month)} $h:$m';
  }

  // ── Layout / direction helpers ────────────────────────────────────────────────
  static bool get isRtl => _lang == 'ar';

  static TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  static TextAlign get textAlignStart =>
      isRtl ? TextAlign.right : TextAlign.left;

  static TextAlign get textAlignEnd =>
      isRtl ? TextAlign.left : TextAlign.right;

  /// Wraps any widget in a Directionality widget matching the current language.
  static Widget wrap(Widget child) =>
      Directionality(textDirection: textDirection, child: child);

  // ── Font family ───────────────────────────────────────────────────────────────
  /// Cairo works well for both Arabic and Latin scripts.
  static String get fontFamily => 'Cairo';
}