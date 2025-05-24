/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RapportScreen extends StatefulWidget {
  final String patientId;

  const RapportScreen({super.key, required this.patientId});

  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  List<FlSpot> _injectionSpots = [];
  double _minInjection = 0;
  double _maxInjection = 20;
  double _minTimestamp = 0;
  double _maxTimestamp = 1;
  bool isLoading = true;
  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadInjectionData();
  }

  Future<void> _loadInjectionData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('injections')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> injectionData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp;
        final dateTime = timestamp.toDate();
        final timeStr = data['tempsInject'] as String? ?? DateFormat.Hm().format(dateTime);
        final dose = data['doseInsuline'] ?? 0;
        final glycemie = data['glycemie'] ?? 'N/A';

        injectionData.add({
          'timestamp': dateTime,
          'time': timeStr,
          'dose': dose,
          'glycemie': glycemie,
        });
      }

      _prepareGraphData(injectionData);
    } catch (e) {
      print('Error loading injection data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _prepareGraphData(List<Map<String, dynamic>> injectionData) {
    _injectionSpots = [];
    
    if (injectionData.isEmpty) {
      _minTimestamp = 0;
      _maxTimestamp = 1;
      _minInjection = 0;
      _maxInjection = 20;
      return;
    }

    // Sort by timestamp
    injectionData.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    // Convert to spots
    _injectionSpots = injectionData.map((injection) {
      final dateTime = injection['timestamp'] as DateTime;
      final timeParts = injection['time'].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final x = (dateTime.millisecondsSinceEpoch / 1000 / 60 / 60).toDouble(); // Convert to hours
      final y = (injection['dose'] as num).toDouble();
      
      return FlSpot(x, y);
    }).toList();

    // Calculate min/max values
    _minTimestamp = _injectionSpots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    _maxTimestamp = _injectionSpots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    _minInjection = _injectionSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    _maxInjection = _injectionSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    // Add some padding
    final timeRange = _maxTimestamp - _minTimestamp;
    _minTimestamp -= timeRange * 0.05;
    _maxTimestamp += timeRange * 0.05;
    
    if (_minInjection < 0) _minInjection = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A7BF7)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rapport des Injections',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _injectionSpots.isEmpty
            ? const Center(child: Text('Aucune donnée d\'injection disponible'))
            : Column(
                children: [
                  Expanded(
                    child: LineChart(
                      LineChartData(
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
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: (_maxInjection - _minInjection) / 5,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: (_maxTimestamp - _minTimestamp) / 5,
                              getTitlesWidget: (value, meta) {
                                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                                    (value * 60 * 60 * 1000).toInt());
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    DateFormat('HH:mm').format(dateTime),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                        minX: _minTimestamp,
                        maxX: _maxTimestamp,
                        minY: _minInjection,
                        maxY: _maxInjection,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((spot) {
                                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                                    (spot.x * 60 * 60 * 1000).toInt());
                                return LineTooltipItem(
                                  '${DateFormat('dd/MM HH:mm').format(dateTime)}\n'
                                  'Dose: ${spot.y.toStringAsFixed(1)} unités\n'
                                  'Glycémie: ${_getGlycemieForSpot(spot.x)} mg/dL',
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
                  const SizedBox(height: 20),
                  const Text(
                    'Évolution des doses d\'insuline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A7BF7)),
                    ),
                ],
              ),
      ),
    );
  }

  String _getGlycemieForSpot(double x) {
    try {
      final spot = _injectionSpots.firstWhere((s) => s.x == x);
      final index = _injectionSpots.indexOf(spot);
      // This is a simplified approach - you might need to adjust based on your data structure
      return index != -1 ? 'N/A' : 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}*/
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diazen/classes/injectiondata.dart';

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

  List<InjectionData> _injectionDataList = [];
  List<FlSpot> _injectionSpots = [];
  double _minInjection = 0;
  double _maxInjection = 20;
  double _minTimestamp = 0;
  double _maxTimestamp = 1;

  @override
  void initState() {
    super.initState();
    _loadInjectionData();
  }

  Future<void> _loadInjectionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Loading injections for patient: ${widget.patientId}');
      
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('patients')
            .doc(widget.patientId)
            .collection('injections')
            .orderBy('timestamp', descending: false)
            .get();
            
        if (snapshot.docs.isEmpty) {
          print('No data in subcollection, trying root collection');
          snapshot = await _firestore
              .collection('injections')
              .where('userId', isEqualTo: widget.patientId)
              .orderBy('timestamp', descending: false)
              .get();
        }
      } catch (e) {
        print('Error with subcollection, trying root collection: $e');
        snapshot = await _firestore
            .collection('injections')
            .where('userId', isEqualTo: widget.patientId)
            .orderBy('timestamp', descending: false)
            .get();
      }

      print('Found ${snapshot.docs.length} injection records');
      
      _injectionDataList = [];

      for (var doc in snapshot.docs) {
        print('Processing doc ${doc.id}');
        final data = doc.data() as Map<String, dynamic>;
        
        dynamic timestampRaw = data['timestamp'];
        DateTime? timestamp;
        
        if (timestampRaw is Timestamp) {
          timestamp = timestampRaw.toDate();
        } else if (timestampRaw is String) {
          try {
            timestamp = DateTime.parse(timestampRaw);
          } catch (e) {
            print('Invalid timestamp format: $timestampRaw');
            continue;
          }
        } else {
          print('Missing or invalid timestamp');
          continue;
        }

        var dose = data['doseInsuline'] ?? data['quantiteGlu'] ?? 0;
        if (dose is String) {
          dose = double.tryParse(dose) ?? 0;
        }
        dose = dose.toDouble();

        String timeStr = data['tempsInject'] as String? ?? 
                        data['time'] as String? ?? 
                        DateFormat.Hm().format(timestamp);

        var glycemie = data['glycemie'] ?? data['glucoseValue'] ?? 'N/A';

        _injectionDataList.add(InjectionData(
          timestamp: timestamp,
          dose: dose,
          glycemie: glycemie.toString(),
          time: timeStr,
        ));
      }

      print('Processed ${_injectionDataList.length} valid injections');
      _prepareGraphData();
    } catch (e) {
      print('Error loading injection data: $e');
      setState(() {
        _errorMessage = 'Erreur de chargement des données. Veuillez réessayer.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _prepareGraphData() {
    print('Preparing graph data with ${_injectionDataList.length} items');
    
    _injectionSpots = _injectionDataList.map((injection) {
      return FlSpot(
        injection.timestamp.millisecondsSinceEpoch.toDouble(),
        injection.dose,
      );
    }).toList();

    if (_injectionSpots.isEmpty) {
      print('No valid spots created');
      _minTimestamp = 0;
      _maxTimestamp = 1;
      _minInjection = 0;
      _maxInjection = 20;
      return;
    }

    _minTimestamp = _injectionSpots.first.x;
    _maxTimestamp = _injectionSpots.last.x;
    _minInjection = _injectionSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    _maxInjection = _injectionSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    final timeRange = _maxTimestamp - _minTimestamp;
    _minTimestamp -= timeRange * 0.1;
    _maxTimestamp += timeRange * 0.1;
    
    _minInjection = (_minInjection - 2).clamp(0, double.infinity);
    _maxInjection += 2;

    print('Graph ranges - X: $_minTimestamp to $_maxTimestamp, Y: $_minInjection to $_maxInjection');
  }

  String _getGlycemieForSpot(double x) {
    try {
      final injection = _injectionDataList.firstWhere(
        (data) => data.timestamp.millisecondsSinceEpoch.toDouble() == x,
      );
      return injection.glycemie;
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rapport des Injections',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A7BF7)))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _injectionSpots.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Aucune donnée d\'injection disponible'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7BF7),
                          ),
                          onPressed: _loadInjectionData,
                          child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                        ),
                        Text('Patient ID: ${widget.patientId}', style: const TextStyle(fontSize: 12)),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: LineChart(
                              LineChartData(
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
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: (_maxInjection - _minInjection) / 5,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: (_maxTimestamp - _minTimestamp) / 5,
                                      getTitlesWidget: (value, meta) {
                                        final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            DateFormat('HH:mm').format(dateTime),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: true),
                                gridData: FlGridData(show: true),
                                minX: _minTimestamp,
                                maxX: _maxTimestamp,
                                minY: _minInjection,
                                maxY: _maxInjection,
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final dateTime = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                        return LineTooltipItem(
                                          '${DateFormat('dd/MM HH:mm').format(dateTime)}\n'
                                          'Dose: ${spot.y.toStringAsFixed(1)} unités\n'
                                          'Glycémie: ${_getGlycemieForSpot(spot.x)} mg/dL',
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
                          const SizedBox(height: 20),
                          const Text(
                            'Évolution des doses d\'insuline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A7BF7),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}