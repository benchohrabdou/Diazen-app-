import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:uuid/uuid.dart';

class LogGlucoseScreen extends StatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  State<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends State<LogGlucoseScreen> {
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TimeOfDay? selectedTime;
  String? selectedContext;
  bool _isSaving = false;

  final List<String> contextOptions = ['Before meal', 'After meal'];

  @override
  void initState() {
    super.initState();
    // Set default time to current time
    selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    glucoseController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _saveLog() async {
    setState(() {
      _isSaving = true;
    });

    // Validate inputs
    if (glucoseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter glucose value')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // Validate glucose is a number
    double? glucoseValue = double.tryParse(glucoseController.text);
    if (glucoseValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid number for glucose')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select time')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (selectedContext == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select context')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Create a unique ID for this glucose log
      final uuid = Uuid();
      final logId = uuid.v4();

      // Create timestamp for the selected time today
      final now = DateTime.now();
      final timestamp = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Create glucose log data
      Map<String, dynamic> glucoseData = {
        'id': logId,
        'userId': currentUser.uid,
        'glucoseValue': glucoseValue,
        'time': selectedTime!.format(context),
        'timestamp': timestamp.toIso8601String(),
        'context': selectedContext,
        'note': noteController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('glucose_logs')
          .doc(logId)
          .set(glucoseData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Glucose log saved successfully')),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving glucose log: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              const Text(
                "Log Glucose",
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF4A7BF7),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Glucose value
                      _buildLabelRow(
                          'Glucose Value (mg/dL)', 'assets/images/glucose.png'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: glucoseController,
                        hintText: 'Enter glucose value',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Time
                      _buildLabelRow(
                          'Time', 'assets/images/last injection.png'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF4A7BF7),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  timePickerTheme: TimePickerThemeData(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(16)),
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildTextField(
                            hintText: selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Select time',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Context
                      _buildLabelRow('Context', 'assets/images/context.png'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedContext,
                            hint: const Text(
                              'Select context',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(
                              fontFamily: 'SfProDisplay',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            items: contextOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedContext = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Note
                      _buildLabelRow('Note', 'assets/images/note.png'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: noteController,
                        hintText:
                            'Optional note (e.g., stress, heavy meal, etc.)',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7BF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SfProDisplay',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget utilitaire pour les titres avec icônes
  Widget _buildLabelRow(String text, String iconPath) {
    return Row(
      children: [
        Image.asset(iconPath, width: 17, height: 17),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: controller == null, // Pour les champs simulés (comme time)
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'SfProDisplay',
          color: Colors.black54,
        ),
        filled: true,
        fillColor: Colors.grey[300],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
