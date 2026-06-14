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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // دالة إنشاء الجداول (مرة واحدة فقط)
  Future<void> _createDB(Database db, int version) async {
    // حذف الجداول القديمة إذا كانت موجودة
    await db.execute('DROP TABLE IF EXISTS cheques');
    await db.execute('DROP TABLE IF EXISTS paiements');
    await db.execute('DROP TABLE IF EXISTS credits');
    await db.execute('DROP TABLE IF EXISTS clients');
    await db.execute('DROP TABLE IF EXISTS categories');
    
    // 1. جدول التصنيفات
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
    
    // 2. جدول العملاء/الموردين
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        telephone TEXT,
        adresse TEXT,
        dateCreation TEXT NOT NULL,
        solde REAL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'CLIENT',
        categoryId INTEGER,
        company TEXT,
        notes TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');
    
    // 3. جدول الكريديات (مع عمود الصورة)
    await db.execute('''
      CREATE TABLE credits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        montantTotal REAL NOT NULL,
        montantRestant REAL NOT NULL,
        dateCredit TEXT NOT NULL,
        description TEXT,
        imagePath TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');
    
    // 4. جدول الدفعات (مع عمود الصورة)
    await db.execute('''
      CREATE TABLE paiements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creditId INTEGER NOT NULL,
        montant REAL NOT NULL,
        datePaiement TEXT NOT NULL,
        note TEXT,
        imagePath TEXT,
        FOREIGN KEY (creditId) REFERENCES credits (id) ON DELETE CASCADE
      )
    ''');
    
    // 5. جدول الشيكات
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

  // دالة تحديث قاعدة البيانات
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE clients ADD COLUMN type TEXT DEFAULT "CLIENT"'); await db.execute('ALTER TABLE clients ADD COLUMN company TEXT'); await db.execute('ALTER TABLE clients ADD COLUMN notes TEXT');  await db.execute('ALTER TABLE clients ADD COLUMN solde REAL DEFAULT 0');
      } catch (e) {
        print('Error adding columns to clients: $e');
      }
    }
    
    if (oldVersion < 3) {
      try {
        await db.execute('''   CREATE TABLE IF NOT EXISTS categories(  id INTEGER PRIMARY KEY AUTOINCREMENT,    name TEXT NOT NULL,type TEXT NOT NULL
          )
        ''');
        await db.execute('ALTER TABLE clients ADD COLUMN categoryId INTEGER');
      } catch (e) {
        print('Error creating categories table: $e');
      }
    }
    
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE credits ADD COLUMN imagePath TEXT');  await db.execute('ALTER TABLE paiements ADD COLUMN imagePath TEXT');
      } catch (e) {
        print('Error adding imagePath columns: $e');
      }
    }
  }

  // ==================== دوال التصنيفات ====================

  Future<Category> createCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap());
    return Category(id: id, name: category.name, type: category.type);
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== دوال العملاء ====================

  Future<Client> createClient(Client client) async {
    final db = await database;
    final id = await db.insert('clients', client.toMap());
    return Client(
      id: id,
      nom: client.nom,
      telephone: client.telephone,
      adresse: client.adresse,
      dateCreation: client.dateCreation,
      solde: client.solde,
      type: client.type,
      categoryId: client.categoryId,
      company: client.company,
      notes: client.notes,
    );
  }

  Future<List<Client>> getClientsByType(String type) async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'nom ASC',
    );
    return result.map((json) => Client.fromMap(json)).toList();
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

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateClientSolde(int clientId) async {
    final solde = await getSoldeClient(clientId);
    final db = await database;
    await db.update(
      'clients',
      {'solde': solde},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  // ==================== دوال الكريديات ====================

  Future<Credit> createCredit(Credit credit) async {
    final db = await database;
    final id = await db.insert('credits', credit.toMap());
    await updateClientSolde(credit.clientId);
    return Credit(
      id: id,
      clientId: credit.clientId,
      montantTotal: credit.montantTotal,
      montantRestant: credit.montantRestant,
      dateCredit: credit.dateCredit,
      description: credit.description,
      imagePath: credit.imagePath,
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
    await updateClientSolde(credit.clientId);
  }

  Future<Credit?> getCredit(int id) async {
    final db = await database;
    final result = await db.query('credits', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Credit.fromMap(result.first);
    }
    return null;
  }

  // ==================== دوال الدفعات ====================

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
      imagePath: paiement.imagePath,
    );
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

  // ==================== دوال الشيكات ====================

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

  // ==================== دوال مساعدة ====================

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

  Future<Map<String, double>> getStatsByType(String type) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(c.montantTotal) as totalCredit,
        SUM(c.montantRestant) as totalRestant,
        SUM(c.montantTotal - c.montantRestant) as totalPaye
      FROM credits c
      JOIN clients cl ON c.clientId = cl.id
      WHERE cl.type = ?
    ''', [type]);

    return {
      'totalCredit': (result.first['totalCredit'] as num?)?.toDouble() ?? 0,
      'totalRestant': (result.first['totalRestant'] as num?)?.toDouble() ?? 0,
      'totalPaye': (result.first['totalPaye'] as num?)?.toDouble() ?? 0,
    };
  }

  // ==================== FIFO Payment ====================

  /// Distributes a payment across open credits, oldest first (FIFO)
  Future<void> createPaiementFIFO(
    int clientId,
    double montant, {
    String? note,
    String? imagePath,
  }) async {
    final db = await database;
    final rows = await db.query(
      'credits',
      where: 'clientId = ? AND montantRestant > 0',
      whereArgs: [clientId],
      orderBy: 'dateCredit ASC', // oldest first
    );
    final openCredits = rows.map((m) => Credit.fromMap(m)).toList();
    if (openCredits.isEmpty) return;

    double remaining = montant;
    final now = DateTime.now();

    for (final credit in openCredits) {
      if (remaining <= 0) break;
      final toPay = remaining >= credit.montantRestant
          ? credit.montantRestant
          : remaining;
      await createPaiement(Paiement(
        creditId: credit.id!,
        montant: toPay,
        datePaiement: now,
        note: note,
        imagePath: imagePath,
      ));
      remaining -= toPay;
    }
  }
Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'clients':   await db.query('clients'),
      'credits':   await db.query('credits'),
      'paiements': await db.query('paiements'),
      'cheques':   await db.query('cheques'),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // امسح كل البيانات القديمة + reset AUTOINCREMENT
      for (final t in ['cheques', 'paiements', 'credits', 'clients']) {
        await txn.delete(t);
        try { await txn.execute("DELETE FROM sqlite_sequence WHERE name='\$t'"); } catch (_) {}
      }

      // استعمل INSERT OR REPLACE باش نتفادى conflict على IDs
      final clientList = (data['clients'] as List?) ?? [];
      for (var r in clientList) {
        final m = Map<String, dynamic>.from(r as Map);
        await txn.rawInsert(
          'INSERT OR REPLACE INTO clients(id,nom,telephone,adresse,dateCreation,solde,type,categoryId,company,notes) VALUES (?,?,?,?,?,?,?,?,?,?)',
          [m['id'], m['nom'], m['telephone'], m['adresse'], m['dateCreation'],
           m['solde'] ?? 0, m['type'] ?? 'CLIENT', m['categoryId'], m['company'], m['notes']],
        );
      }

      final creditList = (data['credits'] as List?) ?? [];
      for (var r in creditList) {
        final m = Map<String, dynamic>.from(r as Map);
        await txn.rawInsert(
          'INSERT OR REPLACE INTO credits(id,clientId,montantTotal,montantRestant,dateCredit,description,imagePath) VALUES (?,?,?,?,?,?,?)',
          [m['id'], m['clientId'], m['montantTotal'], m['montantRestant'],
           m['dateCredit'], m['description'], m['imagePath']],
        );
      }

      final paiementList = (data['paiements'] as List?) ?? [];
      for (var r in paiementList) {
        final m = Map<String, dynamic>.from(r as Map);
        await txn.rawInsert(
          'INSERT OR REPLACE INTO paiements(id,creditId,montant,datePaiement,note,imagePath) VALUES (?,?,?,?,?,?)',
          [m['id'], m['creditId'], m['montant'], m['datePaiement'], m['note'], m['imagePath']],
        );
      }

      final chequeList = (data['cheques'] as List?) ?? [];
      for (var r in chequeList) {
        final m = Map<String, dynamic>.from(r as Map);
        await txn.rawInsert(
          'INSERT OR REPLACE INTO cheques(id,creditId,numero,montant,dateEcheance,banque,imagePath,statut,dateCreation) VALUES (?,?,?,?,?,?,?,?,?)',
          [m['id'], m['creditId'], m['numero'], m['montant'], m['dateEcheance'],
           m['banque'], m['imagePath'], m['statut'] ?? 'EN_ATTENTE', m['dateCreation']],
        );
      }
    });
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in ['cheques', 'paiements', 'credits', 'clients']) {
        await txn.delete(t);
        try { await txn.execute("DELETE FROM sqlite_sequence WHERE name='\$t'"); } catch (_) {}
      }
    });
  }
  // ==================== Flat transactions list with running balance ====================

  Future<List<Map<String, dynamic>>> getAllTransactionsClient(int clientId) async {
    final db = await database;

    final creditRows = await db.query(
      'credits',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );

    List<Map<String, dynamic>> all = [];

    for (final cr in creditRows) {
      all.add({
        'type': 'CREDIT',
        'id': cr['id'],
        'amount': (cr['montantTotal'] as num).toDouble(),
        'date': cr['dateCredit'] as String,
        'description': cr['description'],
        'imagePath': cr['imagePath'],
      });

      final pRows = await db.query(
        'paiements',
        where: 'creditId = ?',
        whereArgs: [cr['id']],
      );
for (final p in pRows) {
  all.add({
    'type': 'PAYMENT',
    'id': p['id'],
    'creditId': cr['id'],    // ← زيد هاد السطر فقط
    'amount': (p['montant'] as num).toDouble(),
    'date': p['datePaiement'] as String,
    'description': p['note'],
    'imagePath': p['imagePath'],
  });
}
    }

    // Sort chronologically
    all.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    // Running balance
    double balance = 0;
    for (final tx in all) {
      if (tx['type'] == 'CREDIT') {
        balance += tx['amount'] as double;
      } else {
        balance -= tx['amount'] as double;
      }
      tx['balance'] = balance;
    }

    return all.reversed.toList(); // most recent first
  }
  
  // ==================== Advanced Search & Filter Support ====================
  
  /// Get the most recent activity date for a client
  /// Considers: credits, payments, and cheques
  Future<DateTime?> getLastActivityDate(int clientId) async {
    final db = await database;
    
    // Get most recent credit date
    final creditResult = await db.rawQuery('''
      SELECT MAX(dateCredit) as maxDate
      FROM credits
      WHERE clientId = ?
    ''', [clientId]);
    final creditDate = creditResult.first['maxDate'] != null
        ? DateTime.tryParse(creditResult.first['maxDate'] as String)
        : null;
    
    // Get most recent payment date
    final paiementResult = await db.rawQuery('''
      SELECT MAX(p.datePaiement) as maxDate
      FROM paiements p
      JOIN credits c ON p.creditId = c.id
      WHERE c.clientId = ?
    ''', [clientId]);
    final paiementDate = paiementResult.first['maxDate'] != null
        ? DateTime.tryParse(paiementResult.first['maxDate'] as String)
        : null;
    
    // Get most recent cheque date
    final chequeResult = await db.rawQuery('''
      SELECT MAX(ch.dateCreation) as maxDate
      FROM cheques ch
      JOIN credits c ON ch.creditId = c.id
      WHERE c.clientId = ?
    ''', [clientId]);
    final chequeDate = chequeResult.first['maxDate'] != null
        ? DateTime.tryParse(chequeResult.first['maxDate'] as String)
        : null;
    
    // Return the most recent of all dates
    final dates = [creditDate, paiementDate, chequeDate]
        .where((d) => d != null)
        .cast<DateTime>()
        .toList();
    
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a)); // most recent first
    return dates.first;
  }
  
  /// Get count of active cheques for a client
  Future<int> getClientChequeCount(int clientId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM cheques ch
      JOIN credits c ON ch.creditId = c.id
      WHERE c.clientId = ?
      AND ch.statut = 'EN_ATTENTE'
    ''', [clientId]);
    
    return (result.first['count'] as int?) ?? 0;
  }
  
}