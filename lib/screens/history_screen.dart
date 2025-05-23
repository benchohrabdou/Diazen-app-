import 'package:flutter/material.dart';
import 'package:diazen/classes/glucose_log.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  // Data structure to hold all history items
  Map<String, Map<String, List<Map<String, dynamic>>>> historyData = {};

  String? selectedMonth;
  List<String> allMonths = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Get current date for default month selection
      final now = DateTime.now();
      final currentMonth = DateFormat('MMMM yyyy').format(now);

      // Initialize data structure
      historyData = {};

      // Load glucose logs
      await _loadGlucoseLogs(currentUser.uid);

      // Load insulin doses
      await _loadInsulinDoses(currentUser.uid);

      // Load injections
      await _loadInjections(currentUser.uid);

      // Load activities
      await _loadActivities(currentUser.uid);

      // Extract all months from the data
      allMonths = historyData.keys.toList();
      allMonths.sort((a, b) {
        // Sort in reverse chronological order
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        return bDate.compareTo(aDate);
      });

      // Always set selectedMonth to a safe value
      if (allMonths.isEmpty) {
        allMonths = [currentMonth];
        selectedMonth = currentMonth;
      } else if (!allMonths.contains(currentMonth)) {
        selectedMonth = allMonths.first;
      } else {
        selectedMonth = currentMonth;
      }

      setState(() {}); // Force UI update after loading data
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading history: $e';
      });
      print('Error loading history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGlucoseLogs(String userId) async {
    try {
      final QuerySnapshot glucoseSnapshot = await _firestore
          .collection('glucose_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in glucoseSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String? ?? '';
        final timeStr = data['time'] as String? ?? '';
        final glucoseValue = data['glucoseValue'] ?? 0;
        final context = data['context'] as String? ?? '';
        final note = data['note'] as String? ?? '';

        if (dateStr.isNotEmpty) {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final month = DateFormat('MMMM yyyy').format(date);

          // Initialize month if not exists
          historyData[month] ??= {};

          // Initialize date if not exists
          historyData[month]![dateStr] ??= [];

          // Add glucose log
          historyData[month]![dateStr]!.add({
            'type': 'glucose',
            'value': glucoseValue.toString(),
            'time': timeStr,
            'context': context,
            'note': note,
          });
        }
      }
    } catch (e) {
      print('Error loading glucose logs: $e');
    }
  }

  Future<void> _loadInsulinDoses(String userId) async {
    try {
      final QuerySnapshot doseSnapshot = await _firestore
          .collection('insulin_doses')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in doseSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String? ?? '';
        final timeStr = data['time'] as String? ?? '';
        final roundedDose = data['roundedDose'] ?? 0;
        final glucoseValue = data['glucoseValue'] ?? 0;
        final mealName = data['mealName'] as String? ?? '';

        if (dateStr.isNotEmpty) {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final month = DateFormat('MMMM yyyy').format(date);

          // Initialize month if not exists
          historyData[month] ??= {};

          // Initialize date if not exists
          historyData[month]![dateStr] ??= [];

          // Add insulin dose calculation
          historyData[month]![dateStr]!.add({
            'type': 'dose_calculation',
            'value': roundedDose.toString(),
            'glucose': glucoseValue.toString(),
            'meal': mealName,
            'time': timeStr,
          });
        }
      }
    } catch (e) {
      print('Error loading insulin doses: $e');
    }
  }

  Future<void> _loadInjections(String userId) async {
    try {
      QuerySnapshot injectionSnapshot = await _firestore
          .collection('injections')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      print(
          'Loaded ${injectionSnapshot.docs.length} injection docs for user $userId');

      // Fallback: if no docs, try loading all injections
      if (injectionSnapshot.docs.isEmpty) {
        print(
            'No injections found for user $userId. Loading all injections for debugging.');
        injectionSnapshot = await _firestore
            .collection('injections')
            .orderBy('timestamp', descending: true)
            .get();
      }

      for (var doc in injectionSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Injection doc: ' + data.toString());
        // Robust field extraction with fallbacks
        dynamic timestampRaw = data['timestamp'];
        String? timeStr = data['tempsInject'] as String?;
        var units = data.containsKey('doseInsuline')
            ? data['doseInsuline']
            : data['quantiteGlu'];
        var glycemie = data['glycemie'];

        DateTime? timestamp;
        if (timestampRaw is String) {
          try {
            timestamp = DateTime.parse(timestampRaw);
          } catch (e) {
            print(
                'Skipping injection doc due to invalid timestamp string: $timestampRaw');
            continue;
          }
        } else if (timestampRaw is Timestamp) {
          timestamp = timestampRaw.toDate();
        } else {
          print(
              'Skipping injection doc due to unknown timestamp type: $timestampRaw');
          continue;
        }

        if (timestamp == null ||
            timeStr == null ||
            units == null ||
            glycemie == null) {
          print('Skipping injection doc due to missing fields: $data');
          continue;
        }
        final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final month = DateFormat('MMMM yyyy').format(date);

        // Initialize month if not exists
        historyData[month] ??= {};
        // Initialize date if not exists
        historyData[month]![dateStr] ??= [];

        // Add injection
        historyData[month]![dateStr]!.add({
          'type': 'injection',
          'value': units.toString(),
          'glycemie': glycemie.toString(),
          'time': timeStr,
        });
      }
    } catch (e) {
      print('Error loading injections: $e');
    }
  }

  Future<void> _loadActivities(String userId) async {
    try {
      final QuerySnapshot activitySnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in activitySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String? ?? '';
        final timeStr = data['time'] as String? ?? '';
        final activityName = data['nom'] as String? ?? '';
        final duration = data['duration'] ?? 30;

        if (dateStr.isNotEmpty) {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final month = DateFormat('MMMM yyyy').format(date);

          // Initialize month if not exists
          historyData[month] ??= {};

          // Initialize date if not exists
          historyData[month]![dateStr] ??= [];

          // Add activity
          historyData[month]![dateStr]!.add({
            'type': 'activity',
            'name': activityName,
            'duration': duration.toString(),
            'time': timeStr,
          });
        }
      }
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'glucose':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🩸 Glucose: ${item['value']} mg/dL",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            Text("🕓 Time: ${item['time']}",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            Text("🍽️ Context: ${item['context']}",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            if (item['note'] != null && item['note'].isNotEmpty)
              Text("📝 Note: ${item['note']}",
                  style: const TextStyle(
                      fontSize: 16, fontFamily: 'SfProDisplay')),
            const Divider(),
          ],
        );

      case 'dose_calculation':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("💉 Calculated Dose: ${item['value']} units",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Color(0xFF4A7BF7),
                    fontWeight: FontWeight.bold)),
            Text("🩸 Glucose: ${item['glucose']} mg/dL",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            Text("🍽️ Meal: ${item['meal']}",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            Text("🕓 Time: ${item['time']}",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            const Divider(),
          ],
        );

      case 'injection':
        // Convert the dose value to an integer for display
        final int doseInt = double.tryParse(item['value'] as String? ?? '0')?.round() ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("💉 Injection: $doseInt units",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
            Text("🩸 Pre-meal glucose: ${item['glycemie']} mg/dL",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            Text("🕓 Time: ${item['time']}",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            const Divider(),
          ],
        );

      case 'activity':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🏃 Activity: ${item['name']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.orange,
                    fontWeight: FontWeight.bold)),
            Text("⏱️ Duration: ${item['duration']} minutes",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            Text("🕓 Time: ${item['time']}",
                style:
                    const TextStyle(fontSize: 16, fontFamily: 'SfProDisplay')),
            const Divider(),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = allMonths;
    if (selectedMonth == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A7BF7)),
        ),
      );
    }
    final days = historyData[selectedMonth]?.keys.toList() ?? [];

    // Sort days in reverse chronological order
    days.sort((a, b) => b.compareTo(a));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A7BF7)),
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A7BF7),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month selector
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4A7BF7)
                                : const Color(0xFFE3ECFB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              month,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'SfProDisplay',
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'SfProDisplay',
                      ),
                    ),
                  ),

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
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                                color: const Color(0xFFEAF1FF),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: _buildHistoryItem(log),
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
