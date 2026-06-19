import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../theme.dart';

/// Export/Import CSV via the native share sheet.
/// iOS users can “Save to Files” (iCloud Drive).
class UploadTab extends StatelessWidget {
  const UploadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final exportService = ExportService();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Tile(
            icon: Icons.upload_file,
            label: 'EXPORT & SHARE',
            desc: 'Save all transactions to CSV and share via iCloud/Files',
            color: VaultColors.neonTeal,
            onTap: () async {
              final txs = await db.allTransactions();
              final file = await exportService.exportToCsv(txs);
              await exportService.shareFile(file);
            },
          ),
          const SizedBox(height: 12),
          _Tile(
            icon: Icons.download,
            label: 'IMPORT CSV',
            desc: 'Load transactions from a previously exported CSV file',
            color: VaultColors.neonPurple,
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final csvString = await file.readAsString();
                final imported = exportService.parseCsv(csvString);
                if (imported.isNotEmpty) {
                  await db.importTransactions(imported, clearFirst: false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imported ${imported.length} transactions',
                          style: VaultFonts.body(13),
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No valid data found',
                            style: VaultFonts.body(13)),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final Color color;
  final VoidCallback? onTap;

  const _Tile(
      {required this.icon,
      required this.label,
      required this.desc,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: VaultFonts.exo(13, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: VaultFonts.body(11, color: VaultColors.textDim)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}