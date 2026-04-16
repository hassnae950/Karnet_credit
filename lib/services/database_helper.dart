// Re-export models so main.dart only needs to import this one file
export '../models/client.dart';
export '../models/credit.dart';
export '../models/paiement.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/credit.dart';
import '../models/paiement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('karnet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        telephone TEXT,
        adresse TEXT,
        dateCreation TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE credits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        montantTotal REAL NOT NULL,
        montantRestant REAL NOT NULL,
        dateCredit TEXT NOT NULL,
        description TEXT,
        statut TEXT NOT NULL DEFAULT 'EN_COURS',
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE paiements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creditId INTEGER NOT NULL,
        montant REAL NOT NULL,
        datePaiement TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (creditId) REFERENCES credits(id) ON DELETE CASCADE
      )
    ''');
  }

  // ===== CLIENTS =====
  Future<Client> createClient(Client client) async {
    final db = await instance.database;
    final id = await db.insert('clients', client.toMap());
    return client.copyWith(id: id);
  }

  Future<List<Client>> getAllClients() async {
    final db = await instance.database;
    final result = await db.query('clients', orderBy: 'nom ASC');
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await instance.database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return db.update('clients', client.toMap(),
        where: 'id = ?', whereArgs: [client.id]);
  }

  Future<int> deleteClient(int id) async {
    final db = await instance.database;
    return db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getSoldeClient(int clientId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(montantRestant) as total FROM credits WHERE clientId = ? AND statut = "EN_COURS"',
      [clientId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ===== CREDITS =====
  Future<Credit> createCredit(Credit credit) async {
    final db = await instance.database;
    final id = await db.insert('credits', credit.toMap());
    return credit.copyWith(id: id);
  }

  Future<List<Credit>> getCreditsClient(int clientId) async {
    final db = await instance.database;
    final result = await db.query(
      'credits',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'dateCredit DESC',
    );
    return result.map((map) => Credit.fromMap(map)).toList();
  }

  Future<int> updateCredit(Credit credit) async {
    final db = await instance.database;
    return db.update('credits', credit.toMap(),
        where: 'id = ?', whereArgs: [credit.id]);
  }

  Future<int> deleteCredit(int id) async {
    final db = await instance.database;
    return db.delete('credits', where: 'id = ?', whereArgs: [id]);
  }

  // ===== PAIEMENTS =====
  Future<Paiement> createPaiement(Paiement paiement) async {
    final db = await instance.database;
    final id = await db.insert('paiements', paiement.toMap());

    // Mettre à jour montantRestant du credit
    final credit = await db
        .query('credits', where: 'id = ?', whereArgs: [paiement.creditId]);
    if (credit.isNotEmpty) {
      double restant =
          (credit.first['montantRestant'] as num).toDouble() - paiement.montant;
      if (restant < 0) restant = 0;
      String statut = restant <= 0 ? 'SOLDE' : 'EN_COURS';
      await db.update(
        'credits',
        {'montantRestant': restant, 'statut': statut},
        where: 'id = ?',
        whereArgs: [paiement.creditId],
      );
    }
    return paiement.copyWith(id: id);
  }

  Future<List<Paiement>> getPaiementsCredit(int creditId) async {
    final db = await instance.database;
    final result = await db.query(
      'paiements',
      where: 'creditId = ?',
      whereArgs: [creditId],
      orderBy: 'datePaiement DESC',
    );
    return result.map((map) => Paiement.fromMap(map)).toList();
  }

  // ===== STATS =====
  Future<Map<String, double>> getStatsGlobales() async {
    final db = await instance.database;
    final totalCredit = await db.rawQuery(
      'SELECT SUM(montantTotal) as total FROM credits',
    );
    final totalRestant = await db.rawQuery(
      'SELECT SUM(montantRestant) as total FROM credits WHERE statut = "EN_COURS"',
    );
    final totalPaye = await db.rawQuery(
      'SELECT SUM(montant) as total FROM paiements',
    );
    return {
      'totalCredit':
          (totalCredit.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalRestant':
          (totalRestant.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalPaye': (totalPaye.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}