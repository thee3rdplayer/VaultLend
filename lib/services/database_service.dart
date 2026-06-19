import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

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
          address TEXT NOT NULL DEFAULT '',
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
      version: 3, // bumped because we added address column
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 3) {
          db.execute(
              "ALTER TABLE transactions ADD COLUMN address TEXT NOT NULL DEFAULT ''");
        }
      },
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

  /// Add a note, optionally change status, and now also update phone & address.
  Future<int> addAudit(int id,
      {required String note,
      String? newStatus,
      String? phone,
      String? address}) async {
    final db = await database;
    final values = <String, dynamic>{'note': note};
    if (newStatus != null) values['status'] = newStatus;
    if (phone != null) values['phone'] = phone;
    if (address != null) values['address'] = address;
    return db.update('transactions', values,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a transaction by id.
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Bulk import – skips duplicates by checking all key fields including address.
  Future<void> importTransactions(List<LoanTransaction> txs,
      {bool clearFirst = false}) async {
    final db = await database;
    if (clearFirst) await db.delete('transactions');

    final batch = db.batch();
    for (final tx in txs) {
      final exists = await db.query(
        'transactions',
        where: 'borrowerName = ? AND phone = ? AND address = ? AND loanDate = ? AND '
            'baseAmount = ? AND interestAmount = ? AND dueDate = ?',
        whereArgs: [
          tx.borrowerName,
          tx.phone,
          tx.address,
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