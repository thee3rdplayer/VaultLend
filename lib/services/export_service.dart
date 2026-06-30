import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';    // v13+
import '../models/transaction.dart';

/// CSV export/import with address column.
class ExportService {
  static const _header =
      'Name,Phone,Address,LoanDate,BaseAmount,InterestAmount,DueDate,Status,Note,CreatedAt';

  String _toCsv(List<LoanTransaction> txs) {
    final rows = txs.map((t) => [
          _escapeCsv(t.borrowerName),
          _escapeCsv(t.phone),
          _escapeCsv(t.address),
          t.loanDate.toIso8601String(),
          t.baseAmount,
          t.interestAmount,
          t.dueDate.toIso8601String(),
          t.status,
          _escapeCsv(t.note ?? ''),
          t.createdAt.toIso8601String(),
        ].join(','));
    return '$_header\n${rows.join('\n')}';
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<File> exportToCsv(List<LoanTransaction> txs) async {
    final csv = _toCsv(txs);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vaultlend_export.csv');
    await file.writeAsString(csv);
    return file;
  }

  /// Use SharePlus.instance.share() – the new v13 API.
  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'VaultLend Transactions',
      ),
    );
  }

  List<LoanTransaction> parseCsv(String csv) {
    final lines = csv.split('\n');
    if (lines.length < 2) return [];
    final dataLines = lines.sublist(1);
    final txs = <LoanTransaction>[];
    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;
      final values = _splitCsvLine(line);
      if (values.length < 10) continue;
      try {
        txs.add(LoanTransaction(
          borrowerName: values[0],
          phone: values[1],
          address: values[2],
          loanDate: DateTime.parse(values[3]),
          baseAmount: double.parse(values[4]),
          interestAmount: double.parse(values[5]),
          dueDate: DateTime.parse(values[6]),
          status: values[7],
          note: values[8].isEmpty ? null : values[8],
          createdAt: DateTime.parse(values[9]),
        ));
      } catch (_) {}
    }
    return txs;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
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