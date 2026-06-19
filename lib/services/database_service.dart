import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';   // ← THIS MUST BE PRESENT

/// All CRUD operations on the local SQLite database.
class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'vaultlend.db'),
      onCreate: (db, version) => db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          borrowerName TEXT NOT NULL,
          phone TEXT NOT NULL,
          loanDate TEXT NOT NULL,
          baseAmount REAL NOT NULL,
          interestAmount REAL NOT NULL,
          totalToPay REAL NOT NULL,
          dueDate TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'unpaid',
          note TEXT,
          createdAt TEXT NOT NULL
        )
      '''),
      version: 2,
    );
  }

  Future<int> insert(LoanTransaction tx) async {
    final db = await database;
    return db.insert('transactions', tx.toMap());
  }

  /// Returns transactions filtered by status, ordered by dueDate ascending.
  Future<List<LoanTransaction>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'dueDate ASC',
    );
    return maps.map((m) => LoanTransaction.fromMap(m)).toList();
  }

  Future<List<LoanTransaction>> allTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'createdAt DESC');
    return maps.map((m) => LoanTransaction.fromMap(m)).toList();
  }

  Future<int> updateStatus(int id, String newStatus) async {
    final db = await database;
    return db.update('transactions', {'status': newStatus},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Add a note and optionally change status (paid toggle).
  Future<int> addAudit(int id,
      {required String note, String? newStatus}) async {
    final db = await database;
    final values = <String, dynamic>{'note': note};
    if (newStatus != null) values['status'] = newStatus;
    return db.update('transactions', values,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Bulk import – skips duplicates by checking key identifying fields.
  Future<void> importTransactions(List<LoanTransaction> txs,
      {bool clearFirst = false}) async {
    final db = await database;
    if (clearFirst) await db.delete('transactions');

    final batch = db.batch();
    for (final tx in txs) {
      // Check for an existing identical transaction
      final exists = await db.query(
        'transactions',
        where: 'borrowerName = ? AND phone = ? AND loanDate = ? AND '
            'baseAmount = ? AND interestAmount = ? AND dueDate = ?',
        whereArgs: [
          tx.borrowerName,
          tx.phone,
          tx.loanDate.toIso8601String(),
          tx.baseAmount,
          tx.interestAmount,
          tx.dueDate.toIso8601String(),
        ],
        limit: 1,
      );
      if (exists.isEmpty) {
        batch.insert('transactions', tx.toMap());
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('transactions');
  }
}