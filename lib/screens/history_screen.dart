import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diazen/classes/glucose_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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
  DateTime? selectedDate;

  List<FlSpot> _glucoseSpots = [];
  double _minGlucose = 0;
  double _maxGlucose = 200;
  double _minTimestamp = 0;
  double _maxTimestamp = 1;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    print('HistoryScreen _loadHistoryData: Function entered.');
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

      // Load all data in parallel
      await Future.wait([
        _loadGlucoseLogs(currentUser.uid),
        _loadInsulinDoses(currentUser.uid),
        _loadInjections(currentUser.uid),
      ]);

      // Prepare data for the glucose graph
      _prepareGlucoseGraphData();

      // Extract all months from the data
      allMonths = historyData.keys.toList();
      allMonths.sort((a, b) {
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        return bDate.compareTo(aDate);
      });

      // Set selected month
      if (allMonths.isEmpty) {
        allMonths = [currentMonth];
        selectedMonth = currentMonth;
      } else if (!allMonths.contains(currentMonth)) {
        selectedMonth = allMonths.first;
      } else {
        selectedMonth = currentMonth;
      }

      setState(() {});
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
          .limit(100) // Limit to last 100 entries for better performance
          .get();

      for (var doc in glucoseSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String? ?? '';
        final timeStr = data['time'] as String? ?? '';
        final glucoseValue = data['glucoseValue'] ?? 0;
        final context = data['context'] as String? ?? '';
        final note = data['note'] as String? ?? '';
        final dynamic timestampRaw = data['timestamp'];

        DateTime? timestamp;
        if (timestampRaw is Timestamp) {
          timestamp = timestampRaw.toDate();
        } else if (timestampRaw is String) {
          try {
            timestamp = DateTime.parse(timestampRaw);
          } catch (e) {
            continue;
          }
        } else {
          continue;
        }

        if (dateStr.isNotEmpty && timestamp != null) {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final month = DateFormat('MMMM yyyy').format(date);

          historyData.putIfAbsent(month, () => {});
          historyData[month]!.putIfAbsent(dateStr, () => []);

          historyData[month]![dateStr]!.add({
            'type': 'glucose',
            'value': glucoseValue.toString(),
            'time': timeStr,
            'context': context,
            'note': note,
            'timestamp': timestamp,
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
      final QuerySnapshot injectionSnapshot = await _firestore
          .collection('injections')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to last 100 entries for better performance
          .get();

      for (var doc in injectionSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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
            continue;
          }
        } else if (timestampRaw is Timestamp) {
          timestamp = timestampRaw.toDate();
        } else {
          continue;
        }

        if (timestamp == null || timeStr == null || units == null || glycemie == null) {
          continue;
        }

        final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final month = DateFormat('MMMM yyyy').format(date);

        historyData.putIfAbsent(month, () => {});
        historyData[month]!.putIfAbsent(dateStr, () => []);

        historyData[month]![dateStr]!.add({
          'type': 'injection',
          'value': units.toString(),
          'glycemie': glycemie.toString(),
          'time': timeStr,
          'timestamp': timestamp,
        });
      }
    } catch (e) {
      print('Error loading injections: $e');
    }
  }

  void _prepareGlucoseGraphData() {
    _glucoseSpots = [];
    _minGlucose = 0;
    _maxGlucose = 200;

    if (historyData.isEmpty) {
      _minTimestamp = 0;
      _maxTimestamp = 1;
      return;
    }

    // Pre-allocate list with estimated size
    List<Map<String, dynamic>> allGlucoseData = [];
    
    // Process data in batches
    historyData.values.forEach((monthData) {
      monthData.values.forEach((dayLogs) {
        // Add glucose logs
        allGlucoseData.addAll(dayLogs.where((log) => log['type'] == 'glucose'));
        
        // Add injection glucose values
        dayLogs.where((log) => log['type'] == 'injection').forEach((injection) {
          if (injection['glycemie'] != null) {
            allGlucoseData.add({
              'type': 'injection_glucose',
              'value': injection['glycemie'],
              'timestamp': injection['timestamp'],
            });
          }
        });
      });
    });

    if (allGlucoseData.isEmpty) {
      _minTimestamp = 0;
      _maxTimestamp = 1;
      return;
    }

    // Sort data by timestamp
    allGlucoseData.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

    // Process data in a single pass
    _minTimestamp = (allGlucoseData.first['timestamp'] as DateTime).millisecondsSinceEpoch.toDouble();
    _maxTimestamp = (allGlucoseData.last['timestamp'] as DateTime).millisecondsSinceEpoch.toDouble();
    _minGlucose = double.infinity;
    _maxGlucose = double.negativeInfinity;

    for (var data in allGlucoseData) {
      final double glucoseValue = double.tryParse(data['value'].toString()) ?? 0;
      final double timestamp = (data['timestamp'] as DateTime).millisecondsSinceEpoch.toDouble();

      _glucoseSpots.add(FlSpot(timestamp, glucoseValue));

      if (glucoseValue < _minGlucose) _minGlucose = glucoseValue;
      if (glucoseValue > _maxGlucose) _maxGlucose = glucoseValue;
    }

    // Add padding
    _minGlucose = (_minGlucose - 20).clamp(0.0, double.infinity);
    _maxGlucose = _maxGlucose + 20;

    double timestampPadding = (_maxTimestamp - _minTimestamp) * 0.05;
    _minTimestamp -= timestampPadding;
    _maxTimestamp += timestampPadding;

    if ((_maxTimestamp - _minTimestamp).abs() < 1e-9) {
      _minTimestamp -= 86400000;
      _maxTimestamp += 86400000;
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
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            Text("🕓 Time: ${item['time']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            Text("🍽️ Context: ${item['context']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            if (item['note'] != null && item['note'].isNotEmpty)
              Text("📝 Note: ${item['note']}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'SfProDisplay',
                      color: Colors.white)),
            const Divider(color: Colors.white30),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text("🩸 Glucose: ${item['glucose']} mg/dL",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            Text("🍽️ Meal: ${item['meal']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            Text("🕓 Time: ${item['time']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            const Divider(color: Colors.white30),
          ],
        );

      case 'injection':
        final int doseInt =
            double.tryParse(item['value'] as String? ?? '0')?.round() ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("💉 Injection: $doseInt units",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text("🩸 Pre-meal glucose: ${item['glycemie']} mg/dL",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            Text("🕓 Time: ${item['time']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'SfProDisplay',
                    color: Colors.white)),
            const Divider(color: Colors.white30),
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
                // Glucose Graph Section
                if (_glucoseSpots.isNotEmpty && _minTimestamp < _maxTimestamp)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: AspectRatio(
                      aspectRatio: 1.7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0, left: 8.0),
                            child: Text(
                              'Glucose Levels Over Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SfProDisplay',
                                color: Color(0xFF4A7BF7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval:
                                      (_maxGlucose - _minGlucose) / 5,
                                  verticalInterval:
                                      (_maxTimestamp - _minTimestamp) / 5,
                                  getDrawingHorizontalLine: (value) {
                                    return const FlLine(
                                      color: Colors.grey,
                                      strokeWidth: 0.5,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return const FlLine(
                                      color: Colors.grey,
                                      strokeWidth: 0.5,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                      reservedSize: 30,
                                      interval:
                                          (_maxTimestamp - _minTimestamp) / 5,
                                      getTitlesWidget: (value, meta) {
                                        final dateTime =
                                            DateTime.fromMillisecondsSinceEpoch(
                                                value.toInt());
                                        String text;
                                        if ((_maxTimestamp - _minTimestamp) <=
                                            86400000 * 2.5) {
                                          text =
                                              DateFormat('jm').format(dateTime);
                                        } else if ((_maxTimestamp -
                                                _minTimestamp) <=
                                            86400000 * 35) {
                                          text = DateFormat('MMM dd')
                                              .format(dateTime);
                                        } else {
                                          text = DateFormat('MMM yyyy')
                                              .format(dateTime);
                                        }
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 8.0,
                                          child: Text(text,
                                              style: const TextStyle(
                                                  fontSize: 10)),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: const Color(0xff37434d), width: 1),
                                ),
                                minX: _minTimestamp,
                                maxX: _maxTimestamp,
                                minY: _minGlucose,
                                maxY: _maxGlucose,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _glucoseSpots,
                                    isCurved: true,
                                    color: const Color(0xFF4A7BF7),
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF4A7BF7)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                      return touchedBarSpots.map((barSpot) {
                                        final date = DateTime.fromMillisecondsSinceEpoch(barSpot.x.toInt());
                                        return LineTooltipItem(
                                          '${DateFormat('MMM dd, HH:mm').format(date)}\n${barSpot.y.toStringAsFixed(0)} mg/dL',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'SfProDisplay',
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Add informative text below the graph
                if (_glucoseSpots.isNotEmpty && _minTimestamp < _maxTimestamp)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text(
                      'X-axis: Time, Y-axis: Glucose Level (mg/dL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'SfProDisplay',
                        color: Colors.grey,
                      ),
                    ),
                  ),

                if (_glucoseSpots.isEmpty &&
                    !_isLoading &&
                    _errorMessage.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No glucose data available to display graph.',
                        style: TextStyle(
                          fontFamily: 'SfProDisplay',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                if (_errorMessage.isNotEmpty && _glucoseSpots.isEmpty)
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

                // Month selector
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          itemCount: allMonths.length,
                          itemBuilder: (context, index) {
                            final month = allMonths[index];
                            final isSelected = month == selectedMonth;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedMonth = month;
                                  selectedDate = null; // Reset selected date when changing month
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
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3ECFB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF4A7BF7),
                            ),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF4A7BF7),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                  selectedMonth = DateFormat('MMMM yyyy').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (selectedDate != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          'Showing data for: ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!)}',
                          style: const TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 16,
                            color: Color(0xFF4A7BF7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedDate = null;
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF4A7BF7),
                          ),
                          label: const Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: 'SfProDisplay',
                              color: Color(0xFF4A7BF7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (_errorMessage.isNotEmpty) ...[
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
                ],

                // Daily Logs Section
                Expanded(
                  child: ListView.builder(
                    key: PageStorageKey(selectedMonth), // Preserve scroll position
                    itemCount: days.length,
                    itemBuilder: (context, dayIndex) {
                      final dateStr = days[dayIndex];
                      // Filter daily logs to include only injections
                      final dailyLogs = historyData[selectedMonth]![dateStr]!.where((item) => item['type'] == 'injection').toList();
 
                      if (dailyLogs.isEmpty) {
                        return const SizedBox.shrink(); // Don't show date if no entries
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        color: const Color(0xFF4A7BF7),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDate(dateStr),
                                style: const TextStyle(
                                  fontFamily: 'SfProDisplay',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...dailyLogs.map((log) => Padding(
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
              ],
            ),
    );
  }
}
