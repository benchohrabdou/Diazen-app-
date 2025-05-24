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

  // Variables pour l'édition de la Sensitivité à l'Insuline
  bool _isSensitiviteEditing = false;
  final TextEditingController _sensitiviteController = TextEditingController();

  // Variables pour l'édition du rICR
  bool _isRICREditing = false;
  final TextEditingController _rICRController = TextEditingController();

  int? _calculatedAge;

  @override
  void initState() {
    super.initState();
    _loadPatientData(); // Charger les données du patient au démarrage
  }

  @override
  void dispose() {
    _sensitiviteController.dispose();
    _rICRController.dispose();
    super.dispose();
  }

  int calculerAge(DateTime dateNaissance) {
    final maintenant = DateTime.now();
    int age = maintenant.year - dateNaissance.year;
    if (maintenant.month < dateNaissance.month ||
        (maintenant.month == dateNaissance.month && maintenant.day < dateNaissance.day)) {
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
          .collection('users') // Collection des utilisateurs
          .doc(widget.patientId) // Utiliser l'ID passé
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _patientData = doc.data();
          _sensitiviteController.text = (_patientData?['sensitiviteInsuline'] ?? '').toString();
          _rICRController.text = (_patientData?['rICR'] ?? '').toString();

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
      }
    } catch (e) {
      setState(() {
        _patientData = {};
      });
      print('Error loading patient data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSensitiviteEditing() {
    setState(() {
      _isSensitiviteEditing = !_isSensitiviteEditing;
      if (!_isSensitiviteEditing) {
        _sensitiviteController.text = (_patientData?['sensitiviteInsuline'] ?? '').toString();
      }
    });
  }

  Future<void> _saveSensitivite() async {
    final newValue = double.tryParse(_sensitiviteController.text);
    if (newValue != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.patientId)
            .update({'sensitiviteInsuline': newValue});
        setState(() {
          _patientData!['sensitiviteInsuline'] = newValue;
          _isSensitiviteEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sensitivité à l\'insuline sauvegardée.')));
      } catch (e) {
        print('Error saving sensitivite: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valeur invalide.')));
    }
  }

  void _toggleRICREditing() {
    setState(() {
      _isRICREditing = !_isRICREditing;
      if (!_isRICREditing) {
        _rICRController.text = (_patientData?['rICR'] ?? '').toString();
      }
    });
  }

  Future<void> _saveRICR() async {
    final newValue = double.tryParse(_rICRController.text);
    if (newValue != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.patientId)
            .update({'rICR': newValue});
        setState(() {
          _patientData!['rICR'] = newValue;
          _isRICREditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('rICR sauvegardé.')));
      } catch (e) {
        print('Error saving rICR: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valeur invalide.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String patientName = 'Loading...';
    if (!_isLoading && _patientData != null) {
      final prenom = _patientData!['prenom'] ?? '';
      final nom = _patientData!['nom'] ?? '';
      patientName = '';
      if(prenom.isNotEmpty) patientName += prenom;
      if(nom.isNotEmpty) patientName += ' ' + nom;
      if(patientName.isEmpty) patientName = 'Patient';
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
        ), ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patientData == null || _patientData!.isEmpty
              ? const Center(
                  child: Text(
                    'Could not load patient data.',
                    style: TextStyle(fontFamily: 'SfProDisplay', color: Colors.black54),
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
                                  'insulin sensitivity: ',
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
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                                            border: const OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                            hintStyle: TextStyle(fontFamily: 'SfProDisplay', color: Colors.white70),
                                          ),
                                        )
                                      : Text(
                                          (_patientData?['sensitiviteInsuline'] ?? 'N/A').toString(),
                                          style: const TextStyle(fontFamily: 'SfProDisplay', fontSize: 16, color: Colors.white),
                                        ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isSensitiviteEditing ? Icons.check : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isSensitiviteEditing ? _saveSensitivite : _toggleSensitiviteEditing,
                                ),
                                if(_isSensitiviteEditing)
                                IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70),
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
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                                            border: const OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                            hintStyle: TextStyle(fontFamily: 'SfProDisplay', color: Colors.white70),
                                          ),
                                        )
                                      : Text(
                                          (_patientData?['rICR'] ?? 'N/A').toString(),
                                          style: const TextStyle(fontFamily: 'SfProDisplay', fontSize: 16, color: Colors.white),
                                        ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isRICREditing ? Icons.check : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isRICREditing ? _saveRICR : _toggleRICREditing,
                                ),
                                if(_isRICREditing)
                                IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70),
                                    onPressed: _toggleRICREditing,
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
    builder: (context) => RapportScreen(patientId: 'patientIdHere'),
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
