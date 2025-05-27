import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/screens/rapport_screen.dart';

class PatientScreen extends StatefulWidget {
  final String patientId; // Correction : recevoir l'ID du patient

  const PatientScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  Map<String, dynamic>? _patientData; // Pour stocker les données du patient
  bool _isLoading = true; // Pour gérer l'état de chargement

  // Données historiques du patient
  List<Map<String, dynamic>> _glucoseLogs = [];
  List<Map<String, dynamic>> _injections = [];

  // Variables pour l'édition de la Sensitivité à l'Insuline
  bool _isSensitiviteEditing = false;
  final TextEditingController _sensitiviteController = TextEditingController();

  // Variables for l'édition du rICR
  bool _isRICREditing = false;
  final TextEditingController _rICRController = TextEditingController();

  // Add variables for Target Glucose
  bool _isTargetGlucoseEditing = false;
  final TextEditingController _targetGlucoseController = TextEditingController();

  int? _calculatedAge;

  @override
  void initState() {
    super.initState();
    _loadPatientData(); // Charger les données du patient au démarrage
    _loadPatientHistory(); // Charger l'historique du patient
  }

  @override
  void dispose() {
    _sensitiviteController.dispose();
    _rICRController.dispose();
    _targetGlucoseController.dispose(); // Dispose the new controller
    // Dispose chart related controllers if any will be added
    super.dispose();
  }

  int calculerAge(DateTime dateNaissance) {
    final maintenant = DateTime.now();
    int age = maintenant.year - dateNaissance.year;
    if (maintenant.month < dateNaissance.month ||
        (maintenant.month == dateNaissance.month &&
            maintenant.day < dateNaissance.day)) {
      age--;
    }
    return age;
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _patientData = doc.data();
          _sensitiviteController.text =
              (_patientData?['sensitiviteInsuline'] ?? '').toString();
          // Safely load rICR, default to empty string if null or not present
          final dynamic rawRICR = _patientData?['ratioInsulineGlucide'];
          if (rawRICR != null) {
            _rICRController.text = rawRICR.toString();
          } else {
            _rICRController.text = '';
          }

          // Load Target Glucose, default to '100' if not present
          final dynamic rawTargetGlucose = _patientData?['targetGlucose'];
          _targetGlucoseController.text = (rawTargetGlucose != null) ? rawTargetGlucose.toString() : '100';

          final dateNaissanceRaw = _patientData?['dateNaissance'];
          if (dateNaissanceRaw != null) {
            DateTime? dateNaissance;
            if (dateNaissanceRaw is Timestamp) {
              dateNaissance = dateNaissanceRaw.toDate();
            } else if (dateNaissanceRaw is String) {
              dateNaissance = DateTime.tryParse(dateNaissanceRaw);
            }
            if (dateNaissance != null) {
              _calculatedAge = calculerAge(dateNaissance);
            }
          }
        });
      } else {
        setState(() {
          _patientData = {};
        });
        print('Patient document with ID ${widget.patientId} does not exist.');
      }
    } catch (e) {
      setState(() {
        _patientData = {}; // Set to empty to indicate loading failed
      });
      print('Error loading patient data for ID ${widget.patientId}: $e');
      // You might want to show a user-friendly error message here too
    } finally {
      // We won't set isLoading to false here, as we also need to load history
    }
  }

  Future<void> _loadPatientHistory() async {
    final patientId = widget.patientId;
    if (patientId.isEmpty) return;

    try {
      // Load Glucose Logs
      final glucoseSnapshot = await FirebaseFirestore.instance
          .collection('glucose_logs')
          .where('userId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit for performance
          .get();
      _glucoseLogs = glucoseSnapshot.docs.map((doc) => doc.data()).toList();

      // Load Injections (containing doseInsuline and glycemie at injection)
      final injectionSnapshot = await FirebaseFirestore.instance
          .collection('injections')
          .where('userId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit for performance
          .get();
      _injections = injectionSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error loading patient history: $e');
      // Show an error message
    } finally {
      setState(() {
        _isLoading =
            false; // Set loading to false after both loads are complete
      });
    }
  }

  void _toggleSensitiviteEditing() {
    setState(() {
      _isSensitiviteEditing = !_isSensitiviteEditing;
      if (!_isSensitiviteEditing) {
        _sensitiviteController.text =
            (_patientData?['sensitiviteInsuline'] ?? '').toString();
      }
    });
  }

  Future<void> _saveSensitivite() async {
    final newValue = double.tryParse(_sensitiviteController.text);
    if (newValue != null && newValue >= 0) { // Allow 0 for sensitivity?
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.patientId)
            .update({'sensitiviteInsuline': newValue});
        setState(() {
          _patientData!['sensitiviteInsuline'] = newValue;
          _isSensitiviteEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sensitivité à l\'insuline sauvegardée.')));
      } catch (e) {
        print('Error saving sensitivite for ID ${widget.patientId}: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la sauvegarde.')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Valeur invalide. Veuillez entrer un nombre valide pour la sensitivité à l\'insuline.')));
    }
  }

  void _toggleRICREditing() {
    setState(() {
      _isRICREditing = !_isRICREditing;
      if (!_isRICREditing) {
        _rICRController.text = (_patientData?['ratioInsulineGlucide'] ?? '').toString();
      }
    });
  }

  Future<void> _saveRICR() async {
    final newValue = double.tryParse(_rICRController.text);
    if (newValue != null && newValue > 0) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.patientId)
            .update({'ratioInsulineGlucide': newValue});
        setState(() {
          _patientData!['ratioInsulineGlucide'] = newValue; // Update local state immediately
          _isRICREditing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ICR sauvegardé.')));
      } catch (e) {
        print('Error saving ICR for ID ${widget.patientId}: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la sauvegarde.')));
      }
    } else if (newValue != null && newValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Valeur invalide. L\'ICR doit être supérieur à 0.')));
    } else {
      // Handle case where input is not a valid number
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez entrer un nombre valide pour l\'ICR.')));
    }
  }

  // Add toggle and save functions for Target Glucose
  void _toggleTargetGlucoseEditing() {
    setState(() {
      _isTargetGlucoseEditing = !_isTargetGlucoseEditing;
      if (!_isTargetGlucoseEditing) {
        _targetGlucoseController.text = (_patientData?['targetGlucose'] ?? '100').toString();
      }
    });
  }

  Future<void> _saveTargetGlucose() async {
    final newValue = double.tryParse(_targetGlucoseController.text);
    if (newValue != null && newValue >= 0) { // Target glucose can be 0 or more
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.patientId)
            .update({'targetGlucose': newValue});
        setState(() {
          _patientData!['targetGlucose'] = newValue;
          _isTargetGlucoseEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Objectif de glycémie sauvegardé.')));
      } catch (e) {
        print('Error saving target glucose for ID ${widget.patientId}: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde.')));
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valeur invalide. Veuillez entrer un nombre valide pour l\'objectif de glycémie.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String patientName = 'Loading...';
    String patientPhone = ''; // To display phone number
    if (!_isLoading && _patientData != null) {
      final prenom = _patientData!['prenom'] ?? '';
      final nom = _patientData!['nom'] ?? '';
      patientPhone = _patientData!['tel'] ?? ''; // Get phone number
      patientName = '';
      if (prenom.isNotEmpty) patientName += prenom;
      if (nom.isNotEmpty) patientName += ' ' + nom;
      if (patientName.isEmpty) patientName = 'Patient';
    } else if (!_isLoading && _patientData == null) {
      patientName = 'Patient Not Found';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Patient ',
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A7BF7)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A7BF7)),
            onPressed: _isLoading
                ? null
                : () {
                    _loadPatientData();
                    _loadPatientHistory();
                  }, // Refresh data on button press
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patientData == null || _patientData!.isEmpty
              ? const Center(
                  child: Text(
                    'Could not load patient data.',
                    style: TextStyle(
                        fontFamily: 'SfProDisplay', color: Colors.black54),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: const Color(0xFF4A7BF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations about patient',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            //name
                            Text(
                              'Name: $patientName',
                              style: const TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 13),
                            //age
                            if (_calculatedAge != null) ...[
                              Text(
                                'Age: $_calculatedAge years',
                                style: const TextStyle(
                                  fontFamily: 'SfProDisplay',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 13),
                            ],
                            // Phone Number
                            if (patientPhone.isNotEmpty) ...[
                              Text(
                                'Phone: $patientPhone',
                                style: const TextStyle(
                                  fontFamily: 'SfProDisplay',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 13),
                            ],
                            //poids
                            if (_patientData?['poids'] != null) ...[
                              Text(
                                'Weight: ${_patientData!['poids']} kg',
                                style: const TextStyle(
                                  fontFamily: 'SfProDisplay',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 13),
                            ],
                            //insulin sensitivity
                            Row(
                              children: [
                                const Text(
                                  'Insulin Sensitivity: ',
                                  style: TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: _isSensitiviteEditing
                                      ? TextField(
                                          controller: _sensitiviteController,
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true),
                                          style: const TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 8.0),
                                            border: const OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54)),
                                            focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white)),
                                            hintStyle: TextStyle(
                                                fontFamily: 'SfProDisplay',
                                                color: Colors.white70),
                                          ),
                                        )
                                      : Text(
                                          (_patientData?[
                                                      'sensitiviteInsuline'] ??
                                                  'N/A')
                                              .toString(),
                                          style: const TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isSensitiviteEditing
                                        ? Icons.check
                                        : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isSensitiviteEditing
                                      ? _saveSensitivite
                                      : _toggleSensitiviteEditing,
                                ),
                                if (_isSensitiviteEditing)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white70),
                                    onPressed: _toggleSensitiviteEditing,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            //icr
                            Row(
                              children: [
                                const Text(
                                  'ICR: ',
                                  style: TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: _isRICREditing
                                      ? TextField(
                                          controller: _rICRController,
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true),
                                          style: const TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 8.0),
                                            border: const OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54)),
                                            focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white)),
                                            hintStyle: TextStyle(
                                                fontFamily: 'SfProDisplay',
                                                color: Colors.white70),
                                          ),
                                        )
                                      : Text(
                                          (_patientData?['ratioInsulineGlucide'] == null ||
                                                  _patientData!['ratioInsulineGlucide']
                                                      .toString()
                                                      .isEmpty)
                                              ? 'N/A'
                                              : (_patientData!['ratioInsulineGlucide'] is num
                                                  ? _patientData!['ratioInsulineGlucide']
                                                      .toString()
                                                  : (double.tryParse(
                                                              _patientData![
                                                                      'ratioInsulineGlucide']
                                                                  .toString())
                                                          ?.toString() ??
                                                      'N/A')),
                                          style: const TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isRICREditing ? Icons.check : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isRICREditing
                                      ? _saveRICR
                                      : _toggleRICREditing,
                                ),
                                if (_isRICREditing)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white70),
                                    onPressed: _toggleRICREditing,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            // Target Glucose
                            Row(
                              children: [
                                const Text(
                                  'Target Glucose (mg/dL): ',
                                  style: TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: _isTargetGlucoseEditing
                                      ? TextField(
                                          controller: _targetGlucoseController,
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true),
                                          style: const TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 8.0),
                                            border: const OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54)),
                                            focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white)),
                                            hintStyle: TextStyle(
                                                fontFamily: 'SfProDisplay',
                                                color: Colors.white70),
                                          ),
                                        )
                                      : Text(
                                          (_patientData?['targetGlucose'] ?? '100').toString(),
                                          style: const TextStyle(
                                              fontFamily: 'SfProDisplay',
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isTargetGlucoseEditing ? Icons.check : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isTargetGlucoseEditing ? _saveTargetGlucose : _toggleTargetGlucoseEditing,
                                ),
                                if(_isTargetGlucoseEditing)
                                IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70),
                                    onPressed: _toggleTargetGlucoseEditing,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      //consulter rapport button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RapportScreen(patientId: widget.patientId),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A7BF7),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'SfProDisplay',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('view report'),
        ),
      ),
    );
  }
}
