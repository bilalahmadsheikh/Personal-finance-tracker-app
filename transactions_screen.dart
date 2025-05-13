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

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;

    String formattedDate = "Unknown date";
try {
  final rawDate = transaction['date'].toString();
  final parsedDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(rawDate).toLocal();
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
      trailing: Text(
        'Rs${amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
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
            Row(
              children: [
                const Text("Type: "),
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
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text("Add Transaction"),
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
