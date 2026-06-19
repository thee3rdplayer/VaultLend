/// A single loan in the ledger.
/// Includes borrower name, phone, address, amounts, dates, status, and note.
class LoanTransaction {
  final int? id;
  final String borrowerName;
  final String phone;               // may include country code
  final String address;             // physical / mailing address
  final DateTime loanDate;
  final double baseAmount;
  final double interestAmount;      // flat interest sum
  final double totalToPay;          // base + interest
  final DateTime dueDate;
  final String status;              // 'unpaid' or 'paid'
  final String? note;
  final DateTime createdAt;

  LoanTransaction({
    this.id,
    required this.borrowerName,
    required this.phone,
    required this.address,
    required this.loanDate,
    required this.baseAmount,
    required this.interestAmount,
    required this.dueDate,
    this.status = 'unpaid',
    this.note,
    DateTime? createdAt,
  })  : totalToPay = baseAmount + interestAmount,
        createdAt = createdAt ?? DateTime.now();

  /// Convert to a map for SQLite insertion.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'borrowerName': borrowerName,
        'phone': phone,
        'address': address,
        'loanDate': loanDate.toIso8601String(),
        'baseAmount': baseAmount,
        'interestAmount': interestAmount,
        'totalToPay': totalToPay,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create a LoanTransaction from a database row map.
  factory LoanTransaction.fromMap(Map<String, dynamic> map) =>
      LoanTransaction(
        id: map['id'] as int?,
        borrowerName: map['borrowerName'] as String,
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        loanDate: DateTime.parse(map['loanDate'] as String),
        baseAmount: (map['baseAmount'] as num).toDouble(),
        interestAmount: (map['interestAmount'] as num?)?.toDouble() ?? 0,
        dueDate: DateTime.parse(map['dueDate'] as String),
        status: map['status'] as String? ?? 'unpaid',
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  bool get isPaid => status == 'paid';

  /// Days until due (negative = overdue).
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}