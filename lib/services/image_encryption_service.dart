// lib/services/image_encryption_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageEncryptionService {
  static final ImageEncryptionService instance =
      ImageEncryptionService._init();
  ImageEncryptionService._init();

  // ═══════════════════════════════════════════════════════════════════════════
  //  AES KEY — مخزن في SharedPreferences + Firebase
  // ═══════════════════════════════════════════════════════════════════════════

  Future<enc.Key> _getKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedKey = prefs.getString('_img_enc_key');

    if (storedKey == null) {
      // 1. حاول تجيب المفتاح من Firebase (بعد reinstall)
      storedKey = await _fetchKeyFromFirebase();
    }

    if (storedKey == null) {
      // 2. أول مرة — ولّد مفتاح جديد
      final phone = prefs.getString('user_phone') ?? 'karnet_default';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final raw = '${phone}_${timestamp}_karnet_secret';
      final hash = sha256.convert(utf8.encode(raw)).toString();
      storedKey = hash.substring(0, 32);
    }

    await prefs.setString('_img_enc_key', storedKey);
    _saveKeyToFirebase(storedKey); // في الخلفية
    return enc.Key.fromUtf8(storedKey);
  }

  Future<String?> _fetchKeyFromFirebase() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final doc = await FirebaseFirestore.instance
          .collection('user_keys')
          .doc(uid)
          .get();
      return doc.data()?['enc_key'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveKeyToFirebase(String key) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('user_keys')
          .doc(uid)
          .set({'enc_key': key}, SetOptions(merge: true));
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ENCRYPT — تشفير الصورة ويحفظها في encrypted_images/
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> encryptImage(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      final imageBytes = await originalFile.readAsBytes();

      final key = await _getKey();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);

      final ivBytes = iv.bytes;
      final encryptedBytes = encrypted.bytes;
      final combined = Uint8List(ivBytes.length + encryptedBytes.length);
      combined.setRange(0, ivBytes.length, ivBytes);
      combined.setRange(ivBytes.length, combined.length, encryptedBytes);

      final encDir = await _getEncryptedDir();
      final fileName = 'enc_${DateTime.now().millisecondsSinceEpoch}.bin';
      final encryptedFile = File('${encDir.path}/$fileName');
      await encryptedFile.writeAsBytes(combined);

      try { await originalFile.delete(); } catch (_) {}

      return encryptedFile.path;
    } catch (e) {
      return originalPath;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DECRYPT → TEMP FILE — للعرض فقط
  // ═══════════════════════════════════════════════════════════════════════════

  Future<File?> decryptImageToTemp(String encryptedPath) async {
    try {
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) return null;

      final combined = await encryptedFile.readAsBytes();
      if (combined.length < 16) return null;

      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);

      final key = await _getKey();
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted(encryptedBytes),
        iv: iv,
      );

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/temp_view_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(decryptedBytes);
      return tempFile;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXPORT للـ BACKUP
  //  فك التشفير محلياً → base64 ديال الصورة الأصلية → Firebase
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, String>> exportDecryptedImagesAsBase64() async {
    final result = <String, String>{};
    try {
      final encDir = await _getEncryptedDir();
      if (!await encDir.exists()) return result;

      final files = encDir.listSync().whereType<File>().toList();
      final key = await _getKey();

      for (final file in files) {
        try {
          final combined = await file.readAsBytes();
          if (combined.length < 16) continue;

          final ivBytes = combined.sublist(0, 16);
          final encryptedBytes = combined.sublist(16);
          final iv = enc.IV(ivBytes);
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
          final decryptedBytes = encrypter.decryptBytes(
            enc.Encrypted(encryptedBytes),
            iv: iv,
          );

          final fileName = file.path.split('/').last;
          result[fileName] = base64Encode(decryptedBytes);
          print('📸 Exported: $fileName');
        } catch (e) {
          print('⚠️ Skip ${file.path}: $e');
        }
      }
    } catch (e) {
      print('❌ exportDecryptedImages error: $e');
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  IMPORT من الـ RESTORE
  //  base64 (صورة أصلية) من Firebase → تشفير جديد → encrypted_images/
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> importAndEncryptImagesFromBase64(
      Map<String, String> imagesMap) async {
    try {
      final encDir = await _getEncryptedDir();
      final key = await _getKey();

      for (final entry in imagesMap.entries) {
        final fileName = entry.key;
        final file = File('${encDir.path}/$fileName');

        if (await file.exists()) continue;

        try {
          final imageBytes = base64Decode(entry.value);

          final iv = enc.IV.fromSecureRandom(16);
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
          final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);

          final ivBytes = iv.bytes;
          final encryptedBytes = encrypted.bytes;
          final combined = Uint8List(ivBytes.length + encryptedBytes.length);
          combined.setRange(0, ivBytes.length, ivBytes);
          combined.setRange(ivBytes.length, combined.length, encryptedBytes);

          await file.writeAsBytes(combined);
          print('✅ Restored & re-encrypted: $fileName');
        } catch (e) {
          print('⚠️ Failed $fileName: $e');
        }
      }
    } catch (e) {
      print('❌ importAndEncryptImages error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  UTILS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> deleteTempFile(String tempPath) async {
    try {
      final file = File(tempPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> deleteEncryptedImage(String encryptedPath) async {
    try {
      final file = File(encryptedPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<Directory> _getEncryptedDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final encDir = Directory('${appDir.path}/encrypted_images');
    if (!await encDir.exists()) await encDir.create(recursive: true);
    return encDir;
  }

  bool isEncrypted(String path) {
    return path.contains('/encrypted_images/') ||
        path.split('/').last.startsWith('enc_');
  }
}