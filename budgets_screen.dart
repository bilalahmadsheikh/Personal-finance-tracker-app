import 'package:flutter/material.dart';
import 'api_service.dart';

class BudgetsScreen extends StatefulWidget {
  final String userId;

  const BudgetsScreen({super.key, required this.userId});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _budgetAmountController = TextEditingController();

  List<Map<String, dynamic>> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  Future<void> _fetchBudgets() async {
    setState(() => _isLoading = true);

    final response = await ApiService.getBudgets(widget.userId);
    if (!mounted) return;

    setState(() {
      _budgets = response;
      _isLoading = false;
    });
  }

  Future<void> _setBudget() async {
    final category = _categoryController.text.trim();
    final amount = double.tryParse(_budgetAmountController.text);

    if (category.isEmpty || amount == null) return;

    final response = await ApiService.setBudget(widget.userId, category, amount);
    if (!mounted) return;

    if (response['message'] == 'Budget updated') {
      _categoryController.clear();
      _budgetAmountController.clear();
      _fetchBudgets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Error setting budget")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Budgets")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            TextField(
              controller: _budgetAmountController,
              decoration: const InputDecoration(labelText: "Budget Amount"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _setBudget,
              child: const Text("Set Budget"),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _budgets.isEmpty
                      ? const Center(child: Text("No budget data available"))
                      : ListView.builder(
                          itemCount: _budgets.length,
                          itemBuilder: (context, index) {
                            final budget = _budgets[index];
                            return ListTile(
                              title: Text(budget['category']),
                              subtitle: Text('Spent: Rs${budget['spent'] ?? 0}'),
                              trailing: Text('Budget: Rs${budget['amount']}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
