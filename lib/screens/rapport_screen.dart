import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diazen/classes/injectiondata.dart';
import 'dart:math' as math;

class RapportScreen extends StatefulWidget {
  final String patientId;

  const RapportScreen({super.key, required this.patientId});

  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  // Data structure to hold all history items
  Map<String, Map<String, List<Map<String, dynamic>>>> historyData = {};

  List<FlSpot> _glucoseSpots = [];
  List<FlSpot> _injectionSpots = [];
  double _minGlucose = 0;
  double _maxGlucose = 200;
  double _minInjection = 0;
  double _maxInjection = 20;
  double _minTimestamp = 0;
  double _maxTimestamp = 1;

  // State variables for overall statistics
  String _avgGlucose = 'N/A';
  String _minGlucoseValue = 'N/A';
  String _maxGlucoseValue = 'N/A';
  String _minGlucoseTimestamp = 'N/A';
  String _maxGlucoseTimestamp = 'N/A';
  String _avgInsulin = 'N/A';
  String _patientICR = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load patient's medical information first
      final userDoc =
          await _firestore.collection('users').doc(widget.patientId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        // Safely load rICR for display
        final dynamic rawRICR = userData?['ratioInsulineGlucide'];
        if (rawRICR != null) {
          setState(() {
            _patientICR = rawRICR.toString();
          });
        } else {
          setState(() {
            _patientICR = 'N/A';
          });
        }

        // Continue with loading other data
        await Future.wait([
          _loadGlucoseLogs(),
          _loadInjections(),
        ]);

        // Calculate statistics after loading all data
        _calculateOverallStatistics();
        _prepareGraphData();

      } else {
        setState(() {
          _errorMessage =
              'Patient document not found for ID ${widget.patientId}';
          _patientICR = 'N/A'; // Ensure ICR is N/A if user doc is missing
        });
        print('Patient document not found for ID ${widget.patientId}');
        }
      } catch (e) {
      setState(() {
        _errorMessage = 'Error loading report data: $e';
        _patientICR = 'N/A'; // Ensure ICR is N/A on error
      });
      print('Error loading report data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGlucoseLogs() async {
    try {
      final QuerySnapshot glucoseSnapshot = await _firestore
          .collection('glucose_logs')
            .where('userId', isEqualTo: widget.patientId)
          .orderBy('timestamp', descending: true)
          .limit(500) // Increase limit for all-time calculations
            .get();

      print('Found ${glucoseSnapshot.docs.length} glucose records');
      print(
          'Patient ID being used for glucose logs query: ${widget.patientId}');
      
      for (var doc in glucoseSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String? ?? '';
        final timeStr = data['time'] as String? ?? '';
        final glucoseValue = data['glucoseValue'] ?? 0;
        final context = data['context'] as String? ?? '';
        final note = data['note'] as String? ?? '';
        final dynamic timestampRaw = data['timestamp'];

        print('Processing glucose log: ${doc.id}');
        print('  dateStr: $dateStr, timeStr: $timeStr, glucoseValue: $glucoseValue, timestampRaw: $timestampRaw');

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

  Future<void> _loadInjections() async {
    try {
      final QuerySnapshot injectionSnapshot = await _firestore
          .collection('injections')
          .where('userId', isEqualTo: widget.patientId)
          .orderBy('timestamp', descending: true)
          .limit(500) // Increase limit for all-time calculations
          .get();

      print('Found ${injectionSnapshot.docs.length} injection records');
      print('Patient ID being used for injections query: ${widget.patientId}');

      for (var doc in injectionSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        dynamic timestampRaw = data['timestamp'];
        String? timeStr = data['tempsInject'] as String?;
        var units = data.containsKey('doseInsuline')
            ? data['doseInsuline']
            : data['quantiteGlu'];
        var glycemie = data['glycemie'];

        print('Processing injection record: ${doc.id}');
        print('  timestampRaw: $timestampRaw, timeStr: $timeStr, units: $units, glycemie: $glycemie');

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

        if (timestamp == null ||
            timeStr == null ||
            units == null ||
            glycemie == null) {
          print('Skipping injection record due to null data.');
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

        // Also add glycemia from injection as a glucose data point
        if (glycemie != null) {
          final glucoseValue = double.tryParse(glycemie.toString());
          if (glucoseValue != null) {
            historyData[month]![dateStr]!.add({
              'type': 'glucose', // Mark it as glucose data
              'value': glucoseValue.toString(),
              'time': timeStr, // Use injection time
              'context': 'Pre-injection', // Add context
              'note': '', // No specific note for this point
              'timestamp': timestamp, // Use injection timestamp
            });
          }
        }
      }
    } catch (e) {
      print('Error in _loadInjections: $e');
      print('Error loading injections: $e');
    }
  }

  void _prepareGraphData() {
    _glucoseSpots = [];
    _injectionSpots = [];
    _minGlucose = 0;
    _maxGlucose = 200;
    _minInjection = 0;
    _maxInjection = 20;

    if (historyData.isEmpty) {
      _minTimestamp = 0;
      _maxTimestamp = 1;
      return;
    }

    print('historyData before processing for graphs: $historyData');

    // Pre-allocate lists with estimated size
    List<Map<String, dynamic>> allGlucoseData = [];
    List<Map<String, dynamic>> allInjectionData = [];

    // Process data in batches
    historyData.values.forEach((monthData) {
      monthData.values.forEach((dayLogs) {
        // Add glucose logs
        allGlucoseData.addAll(dayLogs.where((log) => log['type'] == 'glucose'));

        // Add injection data
        allInjectionData
            .addAll(dayLogs.where((log) => log['type'] == 'injection'));
      });
    });

    if (allGlucoseData.isEmpty && allInjectionData.isEmpty) {
      _minTimestamp = 0;
      _maxTimestamp = 1;
      return;
    }

    // Combine all glucose-related data (glucose logs + pre-injection glycemia)
    List<Map<String, dynamic>> allGlucoseRelatedData = allGlucoseData;
    // Note: Pre-injection glycemia data is already added to historyData as 'glucose' type
    // during _loadInjections, so it's already included in allGlucoseData here.

    // Sort all glucose-related data by timestamp
    allGlucoseRelatedData.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

    // Process glucose data
    if (allGlucoseRelatedData.isNotEmpty) {
      _minTimestamp = (allGlucoseRelatedData.first['timestamp'] as DateTime)
          .millisecondsSinceEpoch
          .toDouble();
      _maxTimestamp = (allGlucoseRelatedData.last['timestamp'] as DateTime)
          .millisecondsSinceEpoch
          .toDouble();
      _minGlucose = double.infinity;
      _maxGlucose = double.negativeInfinity;

      for (var data in allGlucoseRelatedData) {
        final double glucoseValue =
            double.tryParse(data['value'].toString()) ?? 0;
        final double timestamp =
            (data['timestamp'] as DateTime).millisecondsSinceEpoch.toDouble();

        _glucoseSpots.add(FlSpot(timestamp, glucoseValue));
        print('Added glucose spot: $timestamp, $glucoseValue');

        if (glucoseValue < _minGlucose) _minGlucose = glucoseValue;
        if (glucoseValue > _maxGlucose) _maxGlucose = glucoseValue;
      }

      // Add padding for glucose
      _minGlucose = (_minGlucose - 20).clamp(0.0, double.infinity);
      _maxGlucose = _maxGlucose + 20;
    }

    // Process injection data
    if (allInjectionData.isNotEmpty) {
      if (_minTimestamp == 0) {
        _minTimestamp = (allInjectionData.first['timestamp'] as DateTime)
            .millisecondsSinceEpoch
            .toDouble();
        _maxTimestamp = (allInjectionData.last['timestamp'] as DateTime)
            .millisecondsSinceEpoch
            .toDouble();
        _minTimestamp = math.min(
            _minTimestamp,
            (allInjectionData.first['timestamp'] as DateTime)
                .millisecondsSinceEpoch
                .toDouble());
        _maxTimestamp = math.max(
            _maxTimestamp,
            (allInjectionData.last['timestamp'] as DateTime)
                .millisecondsSinceEpoch
                .toDouble());
        _maxTimestamp = math.max(
            _maxTimestamp,
            (allInjectionData.last['timestamp'] as DateTime)
                .millisecondsSinceEpoch
                .toDouble());
      }

      _minInjection = double.infinity;
      _maxInjection = double.negativeInfinity;

      for (var data in allInjectionData) {
        final double doseValue = double.tryParse(data['value'].toString()) ?? 0;
        final double timestamp =
            (data['timestamp'] as DateTime).millisecondsSinceEpoch.toDouble();

        _injectionSpots.add(FlSpot(timestamp, doseValue));
        print('Added injection spot: $timestamp, $doseValue');

        if (doseValue < _minInjection) _minInjection = doseValue;
        if (doseValue > _maxInjection) _maxInjection = doseValue;
      }

      // Add padding for injections
      _minInjection = (_minInjection - 2).clamp(0.0, double.infinity);
      _maxInjection = _maxInjection + 2;
    }

    // Calculate overall min/max timestamp across both datasets
    if (allGlucoseData.isNotEmpty && allInjectionData.isNotEmpty) {
      final minGlucoseTimestamp =
          (allGlucoseData.first['timestamp'] as DateTime)
              .millisecondsSinceEpoch
              .toDouble();
      final maxGlucoseTimestamp = (allGlucoseData.last['timestamp'] as DateTime)
          .millisecondsSinceEpoch
          .toDouble();
      final minInjectionTimestamp =
          (allInjectionData.first['timestamp'] as DateTime)
              .millisecondsSinceEpoch
              .toDouble();
      final maxInjectionTimestamp =
          (allInjectionData.last['timestamp'] as DateTime)
              .millisecondsSinceEpoch
              .toDouble();
    
      _minTimestamp = math.min(minGlucoseTimestamp, minInjectionTimestamp);
      _maxTimestamp = math.max(maxGlucoseTimestamp, maxInjectionTimestamp);
    } else if (allInjectionData.isNotEmpty) {
      // If only injection data is present, min/max timestamp was already set in the previous block
    } else if (allGlucoseData.isNotEmpty) {
      // If only glucose data is present, min/max timestamp was already set in the previous block
    } else {
      // If both are empty, min/max timestamp is 0 and 1
      _minTimestamp = 0;
      _maxTimestamp = 1;
    }

    // Add padding to timestamp axis
    double timestampPadding = (_maxTimestamp - _minTimestamp) * 0.05;
    _minTimestamp -= timestampPadding;
    _maxTimestamp += timestampPadding;

    if ((_maxTimestamp - _minTimestamp).abs() < 1e-9) {
      _minTimestamp -= 86400000; // Subtract 1 day in milliseconds
      _maxTimestamp += 86400000; // Add 1 day in milliseconds
    }

    print(
        'Graph ranges - X: $_minTimestamp to $_maxTimestamp, Y Glucose: $_minGlucose to $_maxGlucose, Y Injection: $_minInjection to $_maxInjection');
    print('Number of glucose spots: ${_glucoseSpots.length}');
    print('Number of injection spots: ${_injectionSpots.length}');
  }

  // Method to calculate overall statistics
  void _calculateOverallStatistics() {
    double totalGlucose = 0;
    int glucoseCount = 0;
    double totalInsulin = 0;
    int insulinCount = 0;
    double minGlucose = double.infinity;
    double maxGlucose = double.negativeInfinity;
    DateTime? minGlucoseTimestamp;
    DateTime? maxGlucoseTimestamp;

    historyData.values.forEach((monthData) {
      monthData.values.forEach((dayLogs) {
        dayLogs.forEach((log) {
          if (log['type'] == 'glucose') {
            final double? glucoseValue =
                double.tryParse(log['value'].toString());
            if (glucoseValue != null) {
              totalGlucose += glucoseValue;
              glucoseCount++;
              final DateTime timestamp = log['timestamp'] as DateTime;

              if (glucoseValue < minGlucose) {
                minGlucose = glucoseValue;
                minGlucoseTimestamp = timestamp;
              }
              if (glucoseValue > maxGlucose) {
                maxGlucose = glucoseValue;
                maxGlucoseTimestamp = timestamp;
              }
            }
          } else if (log['type'] == 'injection') {
            final double? doseValue = double.tryParse(log['value'].toString());
            if (doseValue != null) {
              totalInsulin += doseValue;
              insulinCount++;
            }
          }
        });
      });
    });

    // Store calculated statistics in state variables (you might need to add these)
    // For now, just print them
    print('Overall Statistics:');
    print(
        '  Average Glucose: ${glucoseCount > 0 ? (totalGlucose / glucoseCount).toStringAsFixed(1) : 'N/A'} mg/dL');
    print(
        '  Min Glucose: ${minGlucose != double.infinity ? minGlucose.toStringAsFixed(1) : 'N/A'} mg/dL (at ${minGlucoseTimestamp != null ? DateFormat('dd/MM HH:mm').format(minGlucoseTimestamp!) : 'N/A'})');
    print(
        '  Max Glucose: ${maxGlucose != double.negativeInfinity ? maxGlucose.toStringAsFixed(1) : 'N/A'} mg/dL (at ${maxGlucoseTimestamp != null ? DateFormat('dd/MM HH:mm').format(maxGlucoseTimestamp!) : 'N/A'})');
    print(
        '  Average Insulin: ${insulinCount > 0 ? (totalInsulin / insulinCount).toStringAsFixed(1) : 'N/A'} units');

    // Store statistics in state variables
    _avgGlucose = glucoseCount > 0
        ? (totalGlucose / glucoseCount).toStringAsFixed(1)
        : 'N/A';
    _minGlucoseValue =
        minGlucose != double.infinity ? minGlucose.toStringAsFixed(1) : 'N/A';
    _maxGlucoseValue = maxGlucose != double.negativeInfinity
        ? maxGlucose.toStringAsFixed(1)
        : 'N/A';
    _minGlucoseTimestamp = minGlucoseTimestamp != null
        ? DateFormat('dd/MM HH:mm').format(minGlucoseTimestamp!)
        : 'N/A';
    _maxGlucoseTimestamp = maxGlucoseTimestamp != null
        ? DateFormat('dd/MM HH:mm').format(maxGlucoseTimestamp!)
        : 'N/A';
    _avgInsulin = insulinCount > 0
        ? (totalInsulin / insulinCount).toStringAsFixed(1)
        : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Patient Report',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A7BF7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A7BF7)),
            onPressed: _isLoading ? null : _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A7BF7)))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : (_glucoseSpots.isEmpty && _injectionSpots.isEmpty)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                            'No report data available for this patient.'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7BF7),
                          ),
                          onPressed: _loadReportData,
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                        Text('Patient ID: ${widget.patientId}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            // Glucose Chart
                            if (_glucoseSpots.isNotEmpty) ...[
                              const Text(
                                'Glucose Levels (mg/dL)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SfProDisplay',
                                  color: Color(0xFF4A7BF7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              AspectRatio(
                                aspectRatio: 1.7,
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
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.2),
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.2),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(color: Colors.black26),
                                    ),
                                    minX: _minTimestamp,
                                    maxX: _maxTimestamp,
                                    minY: _minGlucose,
                                    maxY: _maxGlucose,
                                lineBarsData: [
                                  LineChartBarData(
                                        spots: _glucoseSpots,
                                    isCurved: true,
                                        color: Colors.orange,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor:
                                            Colors.blueGrey.withOpacity(0.8),
                                        getTooltipItems:
                                            (List<LineBarSpot> touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final dateTime = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    spot.x.toInt());
                                            return LineTooltipItem(
                                              '${DateFormat('dd/MM HH:mm').format(dateTime)}\n'
                                              'Glucose: ${spot.y.toStringAsFixed(1)} mg/dL',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
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
                              const SizedBox(height: 30),
                              const Text(
                                'x axis: time, y axis: glucose level',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                  fontFamily: 'SfProDisplay',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Injection Chart
                            if (_injectionSpots.isNotEmpty) ...[
                              const Text(
                                'Insulin Doses (units)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SfProDisplay',
                                  color: Color(0xFF4A7BF7),
                                  ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              AspectRatio(
                                aspectRatio: 1.7,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval:
                                          (_maxInjection - _minInjection) / 5,
                                      verticalInterval:
                                          (_maxTimestamp - _minTimestamp) / 5,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.2),
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.2),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(color: Colors.black26),
                                    ),
                                minX: _minTimestamp,
                                maxX: _maxTimestamp,
                                minY: _minInjection,
                                maxY: _maxInjection,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _injectionSpots,
                                        isCurved: true,
                                        color: const Color(0xFF4A7BF7),
                                        barWidth: 3,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor:
                                            Colors.blueGrey.withOpacity(0.8),
                                        getTooltipItems:
                                            (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((spot) {
                                            final dateTime = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    spot.x.toInt());
                                        return LineTooltipItem(
                                          '${DateFormat('dd/MM HH:mm').format(dateTime)}\n'
                                              'Dose: ${spot.y.toStringAsFixed(1)} unités',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
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
                              const SizedBox(height: 30),
                              const Text(
                                'This graph shows the patient\'s insulin doses administered over time.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                  fontFamily: 'SfProDisplay',
                                ),
                                textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                            ],

                            const SizedBox(height: 30),
                            // Overall Statistics Section
                          const Text(
                              'Overall Statistics',
                            style: TextStyle(
                                fontSize: 18,
                              fontWeight: FontWeight.bold,
                                fontFamily: 'SfProDisplay',
                              color: Color(0xFF4A7BF7),
                            ),
                              textAlign: TextAlign.center,
                          ),
                            const SizedBox(height: 10),
                            Card(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              color: const Color(
                                  0xFFE3F2FD), // A light blue background
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Average Glucose: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A7BF7))),
                                    Text('$_avgGlucose mg/dL'),
                                    const SizedBox(height: 8),
                                    Text('Min Glucose: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A7BF7))),
                                    Text(
                                        '$_minGlucoseValue mg/dL (at $_minGlucoseTimestamp)'),
                                    const SizedBox(height: 8),
                                    Text('Max Glucose: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A7BF7))),
                                    Text(
                                        '$_maxGlucoseValue mg/dL (at $_maxGlucoseTimestamp)'),
                                    const SizedBox(height: 8),
                                    Text('Average Insulin: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A7BF7))),
                                    Text('$_avgInsulin units'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SfProDisplay',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'ICR: ',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _patientICR,
                  style: const TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            // ... other patient information ...
                        ],
                      ),
                    ),
    );
  }
}
