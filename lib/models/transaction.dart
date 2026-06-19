/// Immutable data object representing a single loan in the ledger.
class LoanTransaction {
  final int? id;
  final String borrowerName;
  final String phone;              // contact number
  final DateTime loanDate;         // date the money was given
  final double baseAmount;         // principal
  final double interestRate;       // e.g. 0.05 = 5%
  final double amountPlusInterest; // baseAmount * (1 + interestRate)
  final DateTime dueDate;          // payment deadline
  final String status;             // 'unpaid' or 'paid'
  final String? note;
  final String? referralName;
  final String? referralCode;
  final DateTime createdAt;

  LoanTransaction({
    this.id,
    required this.borrowerName,
    required this.phone,
    required this.loanDate,
    required this.baseAmount,
    required this.interestRate,
    required this.amountPlusInterest,
    required this.dueDate,
    this.status = 'unpaid',        // default is unpaid
    this.note,
    this.referralName,
    this.referralCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to a map for SQLite insertion.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'borrowerName': borrowerName,
        'phone': phone,
        'loanDate': loanDate.toIso8601String(),
        'baseAmount': baseAmount,
        'interestRate': interestRate,
        'amountPlusInterest': amountPlusInterest,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'note': note,
        'referralName': referralName,
        'referralCode': referralCode,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create a LoanTransaction from a database row map.
  factory LoanTransaction.fromMap(Map<String, dynamic> map) =>
      LoanTransaction(
        id: map['id'] as int?,
        borrowerName: map['borrowerName'] as String,
        phone: map['phone'] as String? ?? '',
        loanDate: DateTime.parse(map['loanDate'] as String),
        baseAmount: (map['baseAmount'] as num).toDouble(),
        interestRate: (map['interestRate'] as num).toDouble(),
        amountPlusInterest: (map['amountPlusInterest'] as num).toDouble(),
        dueDate: DateTime.parse(map['dueDate'] as String),
        status: map['status'] as String? ?? 'unpaid',
        note: map['note'] as String?,
        referralName: map['referralName'] as String?,
        referralCode: map['referralCode'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  /// Convenience getter: true if the loan is paid.
  bool get isPaid => status == 'paid';

  /// Number of days until due (negative if overdue).
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}