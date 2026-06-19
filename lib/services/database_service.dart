import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

/// Handles all CRUD operations on the local SQLite database.
class DatabaseService {
  static Database? _db;

  /// Lazy singleton: returns the same DB instance once opened.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Creates/opens the database with the updated schema.
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
          interestRate REAL NOT NULL,
          amountPlusInterest REAL NOT NULL,
          dueDate TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'unpaid',
          note TEXT,
          referralName TEXT,
          referralCode TEXT,
          createdAt TEXT NOT NULL
        )
      '''),
      version: 2,  // bumped because we added columns
      onUpgrade: (db, oldVersion, newVersion) {
        // If upgrading from v1, add missing columns
        if (oldVersion < 2) {
          db.execute('ALTER TABLE transactions ADD COLUMN phone TEXT NOT NULL DEFAULT ""');
          db.execute('ALTER TABLE transactions ADD COLUMN loanDate TEXT NOT NULL DEFAULT "2024-01-01"');
          db.execute('ALTER TABLE transactions ADD COLUMN baseAmount REAL NOT NULL DEFAULT 0');
          db.execute('ALTER TABLE transactions ADD COLUMN interestRate REAL NOT NULL DEFAULT 0');
          db.execute('ALTER TABLE transactions ADD COLUMN amountPlusInterest REAL NOT NULL DEFAULT 0');
        }
      },
    );
  }

  /// Insert a new transaction and return its id.
  Future<int> insert(LoanTransaction tx) async {
    final db = await database;
    return db.insert('transactions', tx.toMap());
  }

  /// Retrieve all transactions with a given status, ordered by dueDate ascending.
  Future<List<LoanTransaction>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'dueDate ASC',  // earliest first
    );
    return maps.map((m) => LoanTransaction.fromMap(m)).toList();
  }

  /// Fetch every transaction ever recorded.
  Future<List<LoanTransaction>> allTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'createdAt DESC');
    return maps.map((m) => LoanTransaction.fromMap(m)).toList();
  }

  /// Update only the status field.
  Future<int> updateStatus(int id, String newStatus) async {
    final db = await database;
    return db.update('transactions', {'status': newStatus},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Add audit information (note, referrals) and optionally the paid status.
  Future<int> addAudit(int id,
      {required String note,
      String? referralName,
      String? referralCode,
      String? newStatus}) async {
    final db = await database;
    final values = <String, dynamic>{
      'note': note,
      'referralName': referralName,
      'referralCode': referralCode,
    };
    if (newStatus != null) values['status'] = newStatus;
    return db.update('transactions', values,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Bulk import with duplicate detection.
  /// Skips transactions that already exist based on key identifying fields.
  Future<void> importTransactions(List<LoanTransaction> txs,
      {bool clearFirst = false}) async {
    final db = await database;
    if (clearFirst) await db.delete('transactions');

    final batch = db.batch();
    for (final tx in txs) {
      // Check if an identical transaction already exists
      final exists = await db.query(
        'transactions',
        where: '''
          borrowerName = ? AND
          phone = ? AND
          loanDate = ? AND
          baseAmount = ? AND
          interestRate = ? AND
          amountPlusInterest = ? AND
          dueDate = ?
        ''',
        whereArgs: [
          tx.borrowerName,
          tx.phone,
          tx.loanDate.toIso8601String(),
          tx.baseAmount,
          tx.interestRate,
          tx.amountPlusInterest,
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

  /// Delete all transactions (useful for testing).
  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('transactions');
  }
}