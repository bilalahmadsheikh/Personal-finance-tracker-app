import 'package:flutter/material.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();

  List<Map<String, dynamic>> _savingsGoals = [];

  void _addGoal() {
    final goalName = _goalController.text.trim();
    final targetAmount = double.tryParse(_targetAmountController.text.trim());

    if (goalName.isEmpty || targetAmount == null) return;

    setState(() {
      _savingsGoals.add({
        'name': goalName,
        'target': targetAmount,
        'saved': 0.0, // default progress
      });

      _goalController.clear();
      _targetAmountController.clear();
    });
  }

  void _deleteGoal(int index) {
    setState(() {
      _savingsGoals.removeAt(index);
    });
  }

  void _addSavings(int index, double amount) {
    setState(() {
      _savingsGoals[index]['saved'] += amount;
      if (_savingsGoals[index]['saved'] > _savingsGoals[index]['target']) {
        _savingsGoals[index]['saved'] = _savingsGoals[index]['target'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Savings Goals")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Set your savings goals", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(labelText: "Goal Name"),
            ),
            TextField(
              controller: _targetAmountController,
              decoration: const InputDecoration(labelText: "Target Amount"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addGoal,
              child: const Text("Add Goal"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _savingsGoals.length,
                itemBuilder: (context, index) {
                  final goal = _savingsGoals[index];
                  final percent = (goal['saved'] / goal['target']).clamp(0.0, 1.0);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(goal['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Saved: ₹${goal['saved'].toStringAsFixed(2)} / ₹${goal['target']}"),
                          LinearProgressIndicator(value: percent),
                          TextButton(
                            onPressed: () => _addSavings(index, 1000), // Simulated +₹1000
                            child: const Text("Add ₹1000"),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteGoal(index),
                      ),
                    ),
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
