import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../theme.dart';

/// Full‑screen form to add a new loan.
/// Returns `true` if saved successfully, `null` otherwise.
class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _baseAmountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();

  DateTime _loanDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  /// Calculated total: baseAmount * (1 + interestRate/100)
  double get _total {
    final base = double.tryParse(_baseAmountCtrl.text) ?? 0;
    final rate = double.tryParse(_interestRateCtrl.text) ?? 0;
    return base * (1 + rate / 100);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tx = LoanTransaction(
      borrowerName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      loanDate: _loanDate,
      baseAmount: double.parse(_baseAmountCtrl.text),
      interestRate: double.parse(_interestRateCtrl.text),
      amountPlusInterest: _total,
      dueDate: _dueDate,
      status: 'unpaid', // always starts unpaid
    );

    await context.read<DatabaseService>().insert(tx);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate(bool isLoanDate) async {
    // `now` was unused — removed to satisfy linter
    final picked = await showDatePicker(
      context: context,
      initialDate: isLoanDate ? _loanDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: VaultColors.neonPurple,
                onPrimary: VaultColors.voidBlack,
                surface: VaultColors.card,
                onSurface: VaultColors.textPrimary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isLoanDate) {
          _loanDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.voidBlack,
      appBar: AppBar(
        title: Text('New Loan', style: VaultFonts.exo(18, weight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Borrower Name'),
                style: VaultFonts.raj(16),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                style: VaultFonts.raj(16),
              ),
              const SizedBox(height: 16),
              // Loan date row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Loan Date: ${_loanDate.toString().split(' ')[0]}',
                      style: VaultFonts.body(14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(true),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baseAmountCtrl,
                decoration:
                    const InputDecoration(labelText: 'Base Amount (\$)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: VaultFonts.raj(16),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestRateCtrl,
                decoration:
                    const InputDecoration(labelText: 'Interest Rate (%)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: VaultFonts.raj(16),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              // Auto‑calculated total
              Text(
                'Total to Repay: \$${_total.toStringAsFixed(2)}',
                style: VaultFonts.raj(18,
                    weight: FontWeight.w700, color: VaultColors.neonTeal),
              ),
              const SizedBox(height: 16),
              // Due date row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Due Date: ${_dueDate.toString().split(' ')[0]}',
                      style: VaultFonts.body(14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(false),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('SAVE LOAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}