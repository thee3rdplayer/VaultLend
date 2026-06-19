import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

/// Handles CSV export/import with the extended loan schema.
class ExportService {
  /// Build a CSV string from all transactions.
  String _toCsv(List<LoanTransaction> txs) {
    const header =
        'Name,Phone,LoanDate,BaseAmount,InterestRate,AmountPlusInterest,DueDate,Status,Note,ReferralName,ReferralCode,CreatedAt';
    final rows = txs.map((t) => [
          _escapeCsv(t.borrowerName),
          _escapeCsv(t.phone),
          t.loanDate.toIso8601String(),
          t.baseAmount,
          t.interestRate,
          t.amountPlusInterest,
          t.dueDate.toIso8601String(),
          t.status,
          _escapeCsv(t.note ?? ''),
          _escapeCsv(t.referralName ?? ''),
          _escapeCsv(t.referralCode ?? ''),
          t.createdAt.toIso8601String(),
        ].join(','));
    return '$header\n${rows.join('\n')}';
  }

  /// Wrap a value in quotes if it contains a comma or newline.
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Write CSV to a temporary file, then return the file.
  Future<File> exportToCsv(List<LoanTransaction> txs) async {
    final csv = _toCsv(txs);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vaultlend_export.csv');
    await file.writeAsString(csv);
    return file;
  }

  /// Open the system share sheet (iOS: Save to Files → iCloud Drive).
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'VaultLend Transactions',
    );
  }

  /// Parse a CSV string back into a list of LoanTransaction.
  /// Skips any malformed rows silently.
  List<LoanTransaction> parseCsv(String csv) {
    final lines = csv.split('\n');
    if (lines.length < 2) return [];
    final dataLines = lines.sublist(1); // skip header
    final txs = <LoanTransaction>[];
    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;
      final values = _splitCsvLine(line);
      if (values.length < 12) continue; // need all 12 columns
      try {
        txs.add(LoanTransaction(
          borrowerName: values[0],
          phone: values[1],
          loanDate: DateTime.parse(values[2]),
          baseAmount: double.parse(values[3]),
          interestRate: double.parse(values[4]),
          amountPlusInterest: double.parse(values[5]),
          dueDate: DateTime.parse(values[6]),
          status: values[7],
          note: values[8].isEmpty ? null : values[8],
          referralName: values[9].isEmpty ? null : values[9],
          referralCode: values[10].isEmpty ? null : values[10],
          createdAt: DateTime.parse(values[11]),
        ));
      } catch (_) {
        // Ignore malformed lines
      }
    }
    return txs;
  }

  /// Rudimentary CSV line splitter that respects quoted fields.
  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"'); // escaped quote
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }
}