// lib/services/sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../utils/app_translations.dart';
import 'image_encryption_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  FirebaseFirestore get _fs => FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  String? _syncStatus;

  bool get isSyncing => _isSyncing;
  String? get syncStatus => _syncStatus;

  // ═══════════════════════════════════════════════════════════════════════════
  //  BACKUP — مع حذف القديم أولاً باش ما يرجعوش المحذوفين
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> backupAllData(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _syncStatus = Tr.s('error_invalid_phone');
      notifyListeners();
      return false;
    }

    if (!await hasInternetConnection()) {
      _syncStatus = Tr.s('no_internet_error');
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _syncStatus = Tr.s('backup_in_progress');
    notifyListeners();

    try {
      final allData = await DatabaseHelper.instance.exportAllData();
      final userDocRef = _fs.collection('users').doc(phoneNumber);
      final collections = [
        'clients',
        'credits',
        'paiements',
        'cheques',
        'categories'
      ];

      // ✅ الخطوة 1: امسح كل الـ collections القديمة أولاً
      // باش المحذوفين محلياً يتمسحو من Firestore كذلك
      print('🗑️ Clearing old Firestore data before backup...');
      for (final collName in collections) {
        final oldDocs = await userDocRef.collection(collName).get();
        if (oldDocs.docs.isNotEmpty) {
          // نمسح بـ batches صغيرة (Firestore limit = 500 per batch)
          final deleteBatch = _fs.batch();
          for (final doc in oldDocs.docs) {
            deleteBatch.delete(doc.reference);
          }
          await deleteBatch.commit();
          print('🗑️ Cleared $collName: ${oldDocs.docs.length} docs');
        }
      }

      // ✅ الخطوة 2: اكتب البيانات الجديدة
      print('💾 Writing new data...');
      final writeBatch = _fs.batch();

      if (allData['clients'] != null) {
        for (var client in allData['clients'] as List) {
          final doc =
              userDocRef.collection('clients').doc(client['id'].toString());
          writeBatch.set(doc, _sanitizeData(client));
        }
      }
      if (allData['credits'] != null) {
        for (var credit in allData['credits'] as List) {
          final doc =
              userDocRef.collection('credits').doc(credit['id'].toString());
          writeBatch.set(doc, _sanitizeData(credit));
        }
      }
      if (allData['paiements'] != null) {
        for (var p in allData['paiements'] as List) {
          final doc =
              userDocRef.collection('paiements').doc(p['id'].toString());
          writeBatch.set(doc, _sanitizeData(p));
        }
      }
      if (allData['cheques'] != null) {
        for (var ch in allData['cheques'] as List) {
          final doc = userDocRef.collection('cheques').doc(ch['id'].toString());
          writeBatch.set(doc, _sanitizeData(ch));
        }
      }
      if (allData['categories'] != null) {
        for (var cat in allData['categories'] as List) {
          final doc =
              userDocRef.collection('categories').doc(cat['id'].toString());
          writeBatch.set(doc, _sanitizeData(cat));
        }
      }

      // metadata
      writeBatch.set(
        userDocRef.collection('_metadata').doc('info'),
        {
          'lastBackupTime': FieldValue.serverTimestamp(),
          'appVersion': '2.0.0',
          'deviceId': _getDeviceId(),
          'tablesCount': {
            'clients': (allData['clients'] as List?)?.length ?? 0,
            'credits': (allData['credits'] as List?)?.length ?? 0,
            'paiements': (allData['paiements'] as List?)?.length ?? 0,
            'cheques': (allData['cheques'] as List?)?.length ?? 0,
            'categories': (allData['categories'] as List?)?.length ?? 0,
          },
        },
        SetOptions(merge: true),
      );

      await writeBatch.commit();
      print('✅ Data written to Firestore');

      // ✅ الخطوة 3: Backup الصور
      await _backupImages(phoneNumber);

      _isSyncing = false;
      _syncStatus = Tr.s('backup_success');
      notifyListeners();
      print('✅ Backup successful for $phoneNumber');
      return true;
    } on FirebaseException catch (e) {
      _syncStatus = _mapFirebaseError(e);
      _isSyncing = false;
      notifyListeners();
      print('❌ Firebase backup error: ${e.message}');
      return false;
    } catch (e) {
      _syncStatus = '${Tr.s('backup_failed')}: ${e.toString()}';
      _isSyncing = false;
      notifyListeners();
      print('❌ Backup error: $e');
      return false;
    }
  }

  // ── صور: فك تشفير → base64 → Firestore ─────────────────────────────────────
  Future<void> _backupImages(String phoneNumber) async {
    try {
      final imagesMap =
          await ImageEncryptionService.instance.exportDecryptedImagesAsBase64();

      if (imagesMap.isEmpty) {
        print('ℹ️ No images to backup');
        return;
      }

      print('📸 Backing up ${imagesMap.length} images...');

      final userDocRef = _fs.collection('users').doc(phoneNumber);

      // امسح الصور القديمة أولاً
      final oldImageDocs = await userDocRef.collection('_images').get();
      for (final doc in oldImageDocs.docs) {
        await doc.reference.delete();
      }

      // اكتب الجديدة
      final entries = imagesMap.entries.toList();
      const chunkSize = 3;

      for (int i = 0; i < entries.length; i += chunkSize) {
        final chunk = entries.skip(i).take(chunkSize);
        final chunkMap = <String, String>{};
        for (final e in chunk) {
          chunkMap[e.key] = e.value;
        }
        final chunkIndex = (i / chunkSize).floor();
        await userDocRef
            .collection('_images')
            .doc('chunk_$chunkIndex')
            .set(chunkMap);
      }

      print('✅ Images backup done: ${imagesMap.length} files');
    } catch (e) {
      print('⚠️ Images backup error (non-fatal): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RESTORE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> restoreAllData(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _syncStatus = 'Phone number empty';
      notifyListeners();
      return false;
    }

    try {
      _isSyncing = true;
      _syncStatus = 'جاري الاستعادة...';
      notifyListeners();

      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        final hasLocalData = await _hasLocalData();
        if (hasLocalData) {
          _syncStatus = Tr.s('offline_mode');
          _isSyncing = false;
          notifyListeners();
          return true;
        }
        _syncStatus = Tr.s('no_internet_error');
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final userRef = _fs.collection('users').doc(phoneNumber);

      final clientsCheck = await userRef.collection('clients').limit(1).get();
      if (clientsCheck.docs.isEmpty) {
        _syncStatus = Tr.s('no_backup_found');
        _isSyncing = false;
        notifyListeners();
        return true;
      }

      final data = <String, List<Map<String, dynamic>>>{};
      final collections = [
        'clients',
        'credits',
        'paiements',
        'cheques',
        'categories'
      ];

      for (final collName in collections) {
        try {
          final docs = await userRef.collection(collName).get();
          data[collName] = docs.docs.map((doc) {
            final map = Map<String, dynamic>.from(doc.data());
            for (final key in ['id', 'clientId', 'creditId', 'categoryId']) {
              if (map[key] != null) {
                map[key] = int.tryParse(map[key].toString()) ?? map[key];
              }
            }
            for (final key in [
              'montantTotal',
              'montantRestant',
              'montant',
              'solde'
            ]) {
              if (map[key] != null) {
                map[key] = (map[key] as num).toDouble();
              }
            }
            return map;
          }).toList();
        } catch (e) {
          print('❌ Error downloading $collName: $e');
        }
      }

      await DatabaseHelper.instance.deleteAllData();
      await DatabaseHelper.instance.importData(data);
      await _restoreImages(phoneNumber);

      try {
        await userRef.collection('_metadata').doc('info').update({
          'lastRestoreTime': FieldValue.serverTimestamp(),
          'lastRestoredDevice': _getDeviceId(),
        });
      } catch (_) {}

      _syncStatus = Tr.s('restore_success');
      _isSyncing = false;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _syncStatus = _mapFirebaseError(e);
      _isSyncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _syncStatus = '${Tr.s('restore_failed')}: ${e.toString()}';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // ── صور: Firestore base64 → تشفير محلي ─────────────────────────────────────
  Future<void> _restoreImages(String phoneNumber) async {
    try {
      print('📸 Restoring images...');
      final userDocRef = _fs.collection('users').doc(phoneNumber);
      final chunks = await userDocRef.collection('_images').get();

      if (chunks.docs.isEmpty) {
        print('ℹ️ No images to restore');
        return;
      }

      final allImages = <String, String>{};
      for (final doc in chunks.docs) {
        for (final entry in doc.data().entries) {
          allImages[entry.key] = entry.value as String;
        }
      }

      await ImageEncryptionService.instance
          .importAndEncryptImagesFromBase64(allImages);

      print('✅ Images restored: ${allImages.length} files');
    } catch (e) {
      print('⚠️ Images restore error (non-fatal): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CHECK & FETCH
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> backupExistsForPhone(String phoneNumber) async {
    if (!await hasInternetConnection()) return false;
    try {
      // نشيكيو clients sub-collection مباشرة — مو parent doc
      final snap = await _fs
          .collection('users')
          .doc(phoneNumber)
          .collection('clients')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getLastBackupTime(String phoneNumber) async {
    if (!await hasInternetConnection()) return null;
    try {
      final doc = await _fs
          .collection('users')
          .doc(phoneNumber)
          .collection('_metadata')
          .doc('info')
          .get();
      if (doc.exists) {
        final ts = doc['lastBackupTime'] as Timestamp?;
        return ts?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, int>> getBackupStats(String phoneNumber) async {
    if (!await hasInternetConnection()) return {};
    try {
      final doc = await _fs
          .collection('users')
          .doc(phoneNumber)
          .collection('_metadata')
          .doc('info')
          .get();
      if (doc.exists) {
        final tc = doc['tablesCount'] as Map<String, dynamic>?;
        if (tc != null) return tc.cast<String, int>();
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONNECTIVITY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value == null) return;
      sanitized[key] = value;
    });
    return sanitized;
  }

  Future<bool> _hasLocalData() async {
    try {
      final clients = await DatabaseHelper.instance.getAllClients();
      return clients.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _getDeviceId() => DateTime.now().millisecondsSinceEpoch.toString();

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Tr.s('error_permission_denied');
      case 'not-found':
        return Tr.s('no_backup_found');
      case 'unavailable':
        return Tr.s('firebase_unavailable');
      case 'network-error':
        return Tr.s('no_internet_error');
      default:
        return '${Tr.s('sync_error')}: ${e.code}';
    }
  }

  Future<bool> incrementalSync(String phoneNumber) async {
    return backupAllData(phoneNumber);
  }

  Future<bool> deleteBackupForPhone(String phoneNumber) async {
    if (!await hasInternetConnection()) {
      _syncStatus = Tr.s('no_internet_error');
      notifyListeners();
      return false;
    }
    try {
      final userDocRef = _fs.collection('users').doc(phoneNumber);
      final collections = [
        'clients',
        'credits',
        'paiements',
        'cheques',
        'categories',
        '_metadata',
        '_images',
      ];
      for (final collName in collections) {
        final snap = await userDocRef.collection(collName).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }
      await userDocRef.delete();
      _syncStatus = Tr.s('backup_deleted');
      notifyListeners();
      return true;
    } catch (e) {
      _syncStatus = '${Tr.s('delete_failed')}: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
