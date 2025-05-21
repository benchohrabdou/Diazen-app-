import 'package:flutter/material.dart';
import 'package:diazen/classes/glucose_log.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Map<String, Map<String, List<GlucoseLog>>> historyData = {
    'May 2025': {
      '2025-05-01': [
        GlucoseLog(glucose: '112', time: '08:30 AM', context: 'Before meal', note: 'Light breakfast'),
        GlucoseLog(glucose: '140', time: '01:00 PM', context: 'After meal', note: 'Heavy lunch'),
      ],
      '2025-05-02': [
        GlucoseLog(glucose: '130', time: '07:00 AM', context: 'Before meal'),
      ],
    },
    'April 2025': {
      '2025-04-15': [
        GlucoseLog(glucose: '125', time: '07:45 AM', context: 'Before meal'),
      ],
    },
  };

  final List<String> allMonths = [
    'April 2025',
    'May 2025',
    'June 2025',
    'July 2025',
    'August 2025',
    'September 2025',
    'October 2025',
    'November 2025',
    'December 2025',
  ];

  late String selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = allMonths.first;
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final months = allMonths;
    final days = historyData[selectedMonth]?.keys.toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'SfProDisplay',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final isSelected = month == selectedMonth;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMonth = month;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4A7BF7) : const Color(0xFFE3ECFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SfProDisplay',
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Daily logs
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: days.isEmpty
                  ? const Center(
                      child: Text(
                        'No data for this month',
                        style: TextStyle(
                          fontFamily: 'SfProDisplay',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final logs = historyData[selectedMonth]![day]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          color: const Color(0xFFEAF1FF),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDate(day),
                                  style: const TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...logs.map((log) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("🩸 Glucose: ${log.glucose} mg/dL",
                                              style: const TextStyle(fontSize: 16,fontFamily: 'SfProDisplay')),
                                          Text("🕓 Time: ${log.time}",
                                              style: const TextStyle(fontSize: 16,fontFamily: 'SfProDisplay')),
                                          Text("🍽️ Context: ${log.context}",
                                              style: const TextStyle(fontSize: 16,fontFamily: 'SfProDisplay')),
                                          if (log.note != null && log.note!.isNotEmpty)
                                            Text("📝 Note: ${log.note}",
                                                style: const TextStyle(fontSize: 16,fontFamily: 'SfProDisplay')),
                                          const Divider(),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
