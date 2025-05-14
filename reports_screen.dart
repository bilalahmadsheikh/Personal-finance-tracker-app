import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class ReportsScreen extends StatefulWidget {
  final String userId;
  const ReportsScreen({super.key, required this.userId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = "weekly";
  Map<String, dynamic> _reportData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getReport(widget.userId, _selectedPeriod);
    setState(() {
      _reportData = data;
      _isLoading = false;
    });
  }

  void _onPeriodSelected(String period) {
    setState(() {
      _selectedPeriod = period.toLowerCase();
    });
    _fetchReportData();
  }

  void _exportToPDF() async {
  final status = await Permission.storage.request();

  if (status.isGranted) {
    try {
      final bytes = await ApiService.downloadReportPdf(widget.userId, _selectedPeriod);
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to download PDF")));
        return;
      }

      final dir = await getExternalStorageDirectory();
      final path = "${dir!.path}/finance_report_${_selectedPeriod}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved to: $path')));
      await OpenFile.open(path);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  } else if (await Permission.storage.isPermanentlyDenied) {
    // 🔁 If user permanently denied the permission, open settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage permission permanently denied. Please enable it in settings.')),
    );
    await openAppSettings(); // opens phone settings so user can grant manually
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage permission denied.")));
  }
}

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting as Excel...')),
    );
  }

  Widget _buildInsightRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text("Rs${value ?? 0}")],
      ),
    );
  }

  Widget _buildCategoryList(String label, List categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...categories.map((cat) => Text("- $cat")).toList()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final boldStyle = const TextStyle(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Period selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ["Weekly", "Monthly", "Yearly"].map((period) {
                final isSelected = _selectedPeriod == period.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: () => _onPeriodSelected(period),
                    child: Text(period, style: isSelected ? boldStyle : null),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Report Data
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInsightRow("Total Income", _reportData['income']),
                          _buildInsightRow("Total Expense", _reportData['expense']),
                          _buildInsightRow("Net Savings", _reportData['net_savings']),
                          _buildInsightRow("Average Daily Spending", _reportData['average_daily_spending']),
                          _buildInsightRow("Income-Expense Ratio", _reportData['income_expense_ratio']),
                          _buildInsightRow("Budget Utilization (%)", _reportData['budget_utilization']),
                          const SizedBox(height: 10),
                          _buildCategoryList("Top 3 Spending Categories", _reportData['top_categories'] ?? []),
                          _buildInsightRow("Highest Expense", _reportData['highest_expense']),
                          _buildInsightRow("Highest Income", _reportData['highest_income']),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text("Note: All transactions for the selected period will be included in the report export."),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _exportToPDF, child: const Text("Export as PDF")),
            ElevatedButton(onPressed: _exportToExcel, child: const Text("Export as Excel")),
          ],
        ),
      ),
    );
  }
}
