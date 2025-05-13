import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.14.183:5000";

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

  // Get reports data (can add time filters as needed)
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
}
