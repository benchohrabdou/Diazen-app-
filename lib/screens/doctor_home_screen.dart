import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/screens/patient_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  bool _isLoading = true;
  String _doctorName = "doctor";
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  List<String> _favoritePatientIds = [];
  bool _isPatientsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadDoctorName() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('doctors').doc('doctor1').get();
      if (doc.exists) {
        setState(() {
          _doctorName = doc['prenom'] ?? 'doctor';
          _favoritePatientIds = List<String>.from(doc['favoritePatients'] ?? []);
        });
      }
    } catch (e) {
      // Garde _doctorName par défaut
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPatients() async {
    setState(() => _isPatientsLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      final patients = querySnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      setState(() {
        _allPatients = patients;
        _filteredPatients = patients;
      });
    } catch (e) {
      setState(() {
        _allPatients = [];
        _filteredPatients = [];
      });
    } finally {
      setState(() => _isPatientsLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        final nom = (patient['nom'] ?? '').toLowerCase();
        final prenom = (patient['prenom'] ?? '').toLowerCase();
        return nom.contains(query) || prenom.contains(query);
      }).toList();
    });
  }

  void _toggleFavorite(String patientId) async {
    final isFavorite = _favoritePatientIds.contains(patientId);
    setState(() {
      if (isFavorite) {
        _favoritePatientIds.remove(patientId);
      } else {
        _favoritePatientIds.add(patientId);
      }
    });
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc('doctor1')
        .update({'favoritePatients': _favoritePatientIds});
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFF4A7BF7),
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Do you really want to log out?',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: 'SfProDisplay',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ajouter ici la logique de logout
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF4A7BF7),
                fontFamily: 'SfProDisplay',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome doctor,",
                          style: TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 120,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4A7BF7),
                                  ),
                                ),
                              )
                            : Text(
                                _doctorName.isEmpty ? "doctor" : _doctorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SfProDisplay',
                                  color: Color(0xFF4A7BF7),
                                  fontSize: 24,
                                ),
                              ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xFF4A7BF7),
                      ),
                      color: Colors.white,
                      offset: const Offset(0, 40),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _showLogoutDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontFamily: 'SfProDisplay',
                              color: Color(0xFF4A7BF7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patient...',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(Icons.search, color: Color(0xFF4A7BF7)),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 32,
                      minWidth: 32,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'SfProDisplay'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF4A7BF7),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Favorite patients',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
  height: 150,
  child: _favoritePatientIds.isEmpty
      ? const Text(
          'No favorite patients yet.',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white70,
            fontSize: 16,
          ),
        )
      : ListView.builder(
          shrinkWrap: true,
          itemCount: _favoritePatientIds.length,
          itemBuilder: (context, index) {
            final id = _favoritePatientIds[index];
            final patient = _allPatients.firstWhere(
              (p) => p['id'] == id,
              orElse: () => <String, dynamic>{},
            );
            if (patient.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientScreen(patientId: patient['id']),
                          ),
                        );
                      },
                      child: Text(
                        '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'SfProDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.yellow, size: 20),
                ],
              ),
            );
          },
        ),
),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPatientsLoading)
                const Center(child: CircularProgressIndicator())
              else if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _filteredPatients.isEmpty
                        ? const Center(
                            child: Text(
                              'No patients found.',
                              style: TextStyle(fontFamily: 'SfProDisplay', color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = _filteredPatients[index];
                              return ListTile(
                                title: Text(
                                  '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}',
                                  style: const TextStyle(fontFamily: 'SfProDisplay'),
                                ),
                                //subtitle: Text(patient['email'] ?? ''),
                                trailing: IconButton(
                                  icon: Icon(
                                    _favoritePatientIds.contains(patient['id']) ? Icons.star : Icons.star_border,
                                    color: const Color(0xFF4A7BF7),
                                  ),
                                  onPressed: () => _toggleFavorite(patient['id']),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PatientScreen(patientId: patient['id']),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
