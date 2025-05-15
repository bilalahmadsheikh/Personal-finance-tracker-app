import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'main.dart'; // For LoginScreen navigation
import 'transaction_logs_screen.dart'; // For logs screen

class DashboardScreen extends StatelessWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  List<String> getLastThreeMonthLabels() {
    final now = DateTime.now();
    return List.generate(3, (i) {
      final date = DateTime(now.year, now.month - 2 + i, 1);
      return DateFormat('MMM').format(date);
    });
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabels = getLastThreeMonthLabels();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getDashboardData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Failed to load data"));
          }

          var data = snapshot.data!;
          double totalIncome = (data['totalIncome'] ?? 0).toDouble();
          double totalExpense = (data['totalExpense'] ?? 0).toDouble();
          double netSavings = totalIncome - totalExpense;

          double incomePercentage =
              totalIncome + totalExpense == 0
                  ? 0
                  : (totalIncome / (totalIncome + totalExpense)) * 100;
          double expensePercentage = 100 - incomePercentage;

          List<double> monthlySpending = List<double>.from(
            (data['monthlySpending'] ?? [0, 0, 0]).map(
              (e) => (e as num).toDouble(),
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem("Income", totalIncome, Colors.green),
                        _buildSummaryItem("Expense", totalExpense, Colors.red),
                        _buildSummaryItem("Savings", netSavings, Colors.blue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // View Logs Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  TransactionLogsScreen(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text("View Logs"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pie Chart
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Income vs Expense",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: incomePercentage,
                          title:
                              "Income\n${incomePercentage.toStringAsFixed(1)}%",
                          radius: 80,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: expensePercentage,
                          title:
                              "Expense\n${expensePercentage.toStringAsFixed(1)}%",
                          radius: 80,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Bar Chart
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Monthly Spending",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              int index = value.toInt();
                              if (index >= 0 && index < monthLabels.length) {
                                return Text(
                                  monthLabels[index],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('');
                            },
                            interval: 1,
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        monthlySpending.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              fromY: 0,
                              toY: monthlySpending[index],
                              color: Colors.blue,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₨${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
