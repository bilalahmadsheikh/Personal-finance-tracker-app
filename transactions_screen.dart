import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class TransactionsScreen extends StatefulWidget {
  final String userId;
  const TransactionsScreen({super.key, required this.userId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _transactionType = 'income';

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // Fetch Transactions
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getTransactions(widget.userId);
      if (!mounted) return;
      setState(() {
        _transactions = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load transactions.';
        _isLoading = false;
      });
    }
  }

  // Add Transaction
  Future<void> _addTransaction() async {
    final category = _categoryController.text.trim();
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();
    final date = DateTime.now().toIso8601String();

    if (category.isEmpty || amount == null) return;

    try {
      final response = await ApiService.addTransaction(
        widget.userId,
        category,
        amount,
        _transactionType,
        description,
        date,
      );

      if (!mounted) return;

      if (response['message'] == 'Transaction added successfully') {
        setState(() {
          _transactions.insert(0, {
            'category': category,
            'amount': amount,
            'type': _transactionType,
            'description': description,
            'date': date,
          });
          _categoryController.clear();
          _amountController.clear();
          _descriptionController.clear();
          _transactionType = 'income';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to add transaction")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add transaction')),
      );
    }
  }

  // Open Add Transaction Dialog
  Future<void> _openAddTransactionDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              DropdownButton<String>(
                value: _transactionType,
                onChanged: (String? newValue) {
                  setState(() {
                    _transactionType = newValue!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'income', child: Text("Income")),
                  DropdownMenuItem(value: 'expense', child: Text("Expense")),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _addTransaction();
                Navigator.pop(context); // Close dialog after adding transaction
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Update Transaction
  Future<void> _updateTransaction(int index) async {
    final transaction = _transactions[index];

    // Ensure transaction_id is not null
    if (transaction['transaction_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction ID is missing. Cannot update.")),
      );
      return;
    }

    print('Transaction ID for update: ${transaction['transaction_id']}');  // Debugging step

    // Populate the fields with the transaction data
    _categoryController.text = transaction['category'];
    _amountController.text = transaction['amount'].toString();
    _descriptionController.text = transaction['description'] ?? '';
    _transactionType = transaction['type'];  // Correct variable name

    // Show dialog for updating transaction
    final updatedTransaction = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              DropdownButton<String>(
                value: _transactionType,
                onChanged: (String? newValue) {
                  setState(() {
                    _transactionType = newValue!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'income', child: Text("Income")),
                  DropdownMenuItem(value: 'expense', child: Text("Expense")),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final category = _categoryController.text.trim();
                final amount = double.tryParse(_amountController.text);
                final description = _descriptionController.text.trim();
                if (category.isEmpty || amount == null) return;

                // Return the updated data
                Navigator.pop(context, {
                  'transaction_id': transaction['transaction_id'], // Ensure it's not null
                  'category': category,
                  'amount': amount,
                  'transaction_type': _transactionType,  // Correct variable name
                  'description': description,
                });
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );

    // Handle the response after updating
    if (updatedTransaction != null) {
      final response = await ApiService.updateTransaction(
        widget.userId,
        updatedTransaction['transaction_id'],  // Ensure 'transaction_id' is correct
        updatedTransaction['category'],
        updatedTransaction['amount'],
        updatedTransaction['transaction_type'],  // Correct variable name
        updatedTransaction['description'],
      );
      if (response['message'] == 'Transaction updated successfully') {
        setState(() {
          _transactions[index] = updatedTransaction;
        });
      }
    }
  }

  // Show Deleted Transactions
  void _showDeletedTransactionsDialog() async {
    final backups = await ApiService.getDeletedTransactions(widget.userId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deleted Transactions"),
        content: backups.isEmpty
            ? const Text("No deleted transactions.")
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final tx = backups[index];
                    return ListTile(
                      title: Text(tx['category']),
                      subtitle: Text("Rs${tx['amount']} — ${tx['transaction_type']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.undo, color: Colors.green),
                        onPressed: () async {
                          final restore = await ApiService.restoreTransaction(tx['backup_id']);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(restore['message'] ?? 'Restored')),
                          );
                          _fetchTransactions();
                        },
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // Build Transaction Tile
  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final double amount =
        double.tryParse(transaction['amount'].toString()) ?? 0.0;

    String formattedDate = "Unknown date";
    try {
      final rawDate = transaction['date'].toString();
      final parsedDate =
          DateFormat(
            "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
          ).parseUtc(rawDate).toLocal();
      formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      debugPrint("❌ Date parsing failed for ${transaction['date']}: $e");
    }

    return ListTile(
      leading: Icon(
        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
        color: isIncome ? Colors.green : Colors.red,
      ),
      title: Text(transaction['category']),
      subtitle: Text("${transaction['description'] ?? ''}\n$formattedDate"),
      isThreeLine: true,
      trailing: SizedBox(
        width: 120, // Give enough space for the delete button
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Rs${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Delete",
              onPressed: () async {
                final response = await ApiService.deleteTransaction(transaction['transaction_id']);
                final backupId = response['backup_id'];
                final message = response['message'];

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message ?? 'Deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        final undo = await ApiService.restoreTransaction(backupId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(undo['message'] ?? 'Restored')),
                        );
                        _fetchTransactions();
                      },
                    ),
                  ),
                );

                _fetchTransactions();
              },
            ),
          ],
        ),
      ),
      onTap: () => _updateTransaction(_transactions.indexOf(transaction)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transactions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _openAddTransactionDialog,
              child: const Text("Add Transaction"),
            ),
            const SizedBox(height: 20),
            // Button to show deleted transactions
            ElevatedButton.icon(
              onPressed: _showDeletedTransactionsDialog,
              icon: const Icon(Icons.delete_outline),
              label: const Text("Deleted Transactions"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _transactions.isEmpty
                      ? const Center(child: Text("No transactions yet."))
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionTile(_transactions[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
