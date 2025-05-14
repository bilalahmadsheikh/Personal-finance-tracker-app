import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Sample events map: Replace this with actual transaction data from your backend or local state
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime.utc(2025, 4, 5): [
      {'category': 'Groceries', 'amount': 1200, 'type': 'expense'},
    ],
    DateTime.utc(2025, 4, 6): [
      {'category': 'Salary', 'amount': 20000, 'type': 'income'},
      {'category': 'Dining Out', 'amount': 800, 'type': 'expense'},
    ],
  };

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text("Calendar View")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Transactions on selected date:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: selectedEvents.isEmpty
                  ? const Text("No transactions.")
                  : ListView.builder(
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, index) {
                        final event = selectedEvents[index];
                        return ListTile(
                          leading: Icon(
                            event['type'] == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: event['type'] == 'income' ? Colors.green : Colors.red,
                          ),
                          title: Text(event['category']),
                          trailing: Text(
                            '₹${event['amount']}',
                            style: TextStyle(
                              color: event['type'] == 'income' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
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
