import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        telephone TEXT,
        adresse TEXT,
        dateCreation TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE credits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        montantTotal REAL NOT NULL,
        montantRestant REAL NOT NULL,
        dateCredit TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE paiements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creditId INTEGER NOT NULL,
        montant REAL NOT NULL,
        datePaiement TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cheques(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creditId INTEGER NOT NULL,
        numero TEXT NOT NULL,
        montant REAL NOT NULL,
        dateEcheance TEXT NOT NULL,
        banque TEXT,
        imagePath TEXT,
        statut TEXT DEFAULT 'EN_ATTENTE',
        dateCreation TEXT NOT NULL,
        FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cheques(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          creditId INTEGER NOT NULL,
          numero TEXT NOT NULL,
          montant REAL NOT NULL,
          dateEcheance TEXT NOT NULL,
          banque TEXT,
          imagePath TEXT,
          statut TEXT DEFAULT 'EN_ATTENTE',
          dateCreation TEXT NOT NULL,
          FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ==================== CLIENT METHODS ====================
  Future<Client> createClient(Client client) async {
    final db = await database;
    final id = await db.insert('clients', client.toMap());
    return Client(
      id: id,
      nom: client.nom,
      telephone: client.telephone,
      adresse: client.adresse,
      dateCreation: client.dateCreation,
    );
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'nom ASC');
    return result.map((json) => Client.fromMap(json)).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Client.fromMap(result.first);
    }
    return null;
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CREDIT METHODS ====================
  Future<Credit> createCredit(Credit credit) async {
    final db = await database;
    final id = await db.insert('credits', credit.toMap());
    return Credit(
      id: id,
      clientId: credit.clientId,
      montantTotal: credit.montantTotal,
      montantRestant: credit.montantRestant,
      dateCredit: credit.dateCredit,
      description: credit.description,
    );
  }

  Future<List<Credit>> getCreditsClient(int clientId) async {
    final db = await database;
    final result = await db.query(
      'credits',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'dateCredit DESC',
    );
    return result.map((json) => Credit.fromMap(json)).toList();
  }

  Future<void> updateCredit(Credit credit) async {
    final db = await database;
    await db.update(
      'credits',
      credit.toMap(),
      where: 'id = ?',
      whereArgs: [credit.id],
    );
  }

  // ==================== PAIEMENT METHODS ====================
  Future<Paiement> createPaiement(Paiement paiement) async {
    final db = await database;
    final id = await db.insert('paiements', paiement.toMap());

    final credit = await getCredit(paiement.creditId);
    if (credit != null) {
      credit.montantRestant -= paiement.montant;
      await updateCredit(credit);
    }

    return Paiement(
      id: id,
      creditId: paiement.creditId,
      montant: paiement.montant,
      datePaiement: paiement.datePaiement,
      note: paiement.note,
    );
  }

  Future<Credit?> getCredit(int id) async {
    final db = await database;
    final result = await db.query('credits', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Credit.fromMap(result.first);
    }
    return null;
  }

  Future<List<Paiement>> getPaiementsCredit(int creditId) async {
    final db = await database;
    final result = await db.query(
      'paiements',
      where: 'creditId = ?',
      whereArgs: [creditId],
      orderBy: 'datePaiement DESC',
    );
    return result.map((json) => Paiement.fromMap(json)).toList();
  }

  // ==================== CHEQUE METHODS ====================
  Future<Cheque> createCheque(Cheque cheque) async {
    final db = await database;
    final id = await db.insert('cheques', cheque.toMap());
    return Cheque(
      id: id,
      creditId: cheque.creditId,
      numero: cheque.numero,
      montant: cheque.montant,
      dateEcheance: cheque.dateEcheance,
      banque: cheque.banque,
      imagePath: cheque.imagePath,
      statut: cheque.statut,
      dateCreation: cheque.dateCreation,
    );
  }

  Future<List<Cheque>> getChequesCredit(int creditId) async {
    final db = await database;
    final result = await db.query(
      'cheques',
      where: 'creditId = ?',
      whereArgs: [creditId],
      orderBy: 'dateCreation DESC',
    );
    return result.map((json) => Cheque.fromMap(json)).toList();
  }

  Future<void> updateChequeStatut(int id, String statut) async {
    final db = await database;
    await db.update(
      'cheques',
      {'statut': statut},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== HELPER METHODS ====================
  Future<double> getSoldeClient(int clientId) async {
    final credits = await getCreditsClient(clientId);
    double solde = 0;
    for (var credit in credits) {
      solde += credit.montantRestant;
    }
    return solde;
  }

  Future<Map<String, double>> getStatsGlobales() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(credits.montantTotal) as totalCredit,
        SUM(credits.montantRestant) as totalRestant,
        SUM(credits.montantTotal - credits.montantRestant) as totalPaye
      FROM credits
    ''');

    return {
      'totalCredit': (result.first['totalCredit'] as num?)?.toDouble() ?? 0,
      'totalRestant': (result.first['totalRestant'] as num?)?.toDouble() ?? 0,
      'totalPaye': (result.first['totalPaye'] as num?)?.toDouble() ?? 0,
    };
  }
}