import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
       // Your Flask server URL

  // User registration
  static Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // User login
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Add transaction
  static Future<Map<String, dynamic>> addTransaction(
    String userId,
    String category,
    double amount,
    String type,
    String description,
    String date,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add-transaction"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "category": category,
          "amount": amount,
          "transaction_type": type,
          "description": description,
          "date": date,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Delete transaction (moves to backup table)
  static Future<Map<String, dynamic>> deleteTransaction(
    int transactionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete-transaction"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"transaction_id": transactionId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"message": "Failed to delete transaction: $e"};
    }
  }

  // Restore transaction from backup table
  static Future<Map<String, dynamic>> restoreTransaction(int backupId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/restore-transaction"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"backup_id": backupId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"message": "Failed to restore transaction: $e"};
    }
  }

  // Get deleted transactions
  static Future<List<Map<String, dynamic>>> getDeletedTransactions(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-deleted-transactions/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get transactions
  static Future<List<Map<String, dynamic>>> getTransactions(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-transactions/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Update transaction
  static Future<Map<String, dynamic>> updateTransaction(
    String userId,
    int transactionId,
    String category,
    double amount,
    String type,
    String description,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-transaction"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "transaction_id": transactionId,
          "user_id": userId,
          "category": category,
          "amount": amount,
          "transaction_type": type,
          "description": description,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Set or update budget
  static Future<Map<String, dynamic>> setBudget(
    String userId,
    String category,
    double amount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/set-budget/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"category": category, "amount": amount}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Get budgets
  static Future<List<Map<String, dynamic>>> getBudgets(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-budgets/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get dashboard data
  static Future<Map<String, dynamic>> getDashboardData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-dashboard/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // Get reports data
  static Future<Map<String, dynamic>> getReport(
    String userId,
    String period,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-report/$userId?period=$period"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Set savings goal
  static Future<Map<String, dynamic>> addSavingsGoal(
    String userId,
    String goal,
    double targetAmount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add-savings-goal"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "goal": goal,
          "targetAmount": targetAmount,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Download report PDF
  static Future<Uint8List?> downloadReportPdf(
    String userId,
    String period,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/download-report/$userId?period=$period"),
        headers: {"Accept": "application/pdf"},
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get savings goals
  static Future<List<Map<String, dynamic>>> getSavingsGoals(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-savings-goals/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Settings update (e.g., email summary toggle)
  static Future<Map<String, dynamic>> updateSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-settings/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(settings),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Error: ${response.statusCode} ${response.body}"};
      }
    } catch (e) {
      return {"message": "Failed to connect to server: $e"};
    }
  }

  // Get calendar-based transactions
  static Future<List<Map<String, dynamic>>> getTransactionsByDate(
    String userId,
    String date,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-transactions-date/$userId?date=$date"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // New: Get transaction logs
  static Future<List<Map<String, dynamic>>> getTransactionLogs(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-transaction-logs/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
