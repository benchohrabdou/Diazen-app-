import 'package:diazen/screens/activity_screen.dart';
import 'package:diazen/screens/add_plate_screen.dart';
import 'package:flutter/material.dart';

class CalculateDoseScreen extends StatefulWidget {
  const CalculateDoseScreen({super.key});

  @override
  State<CalculateDoseScreen> createState() => _CalculateDoseScreenState();
}

class _CalculateDoseScreenState extends State<CalculateDoseScreen> {
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController mealController = TextEditingController();

  bool unplannedActivity = false;
  bool plannedActivity = false;
  bool _isSaving = false;

  final double targetGlucose = 100;
  final double isf = 50;
  final double icr = 10;

  double calculateDose(double glucose, double carbs) {
    double correctionDose = (glucose - targetGlucose) / isf;
    double mealDose = carbs / icr;
    return (correctionDose + mealDose).clamp(0, double.infinity);
  }

  Future<bool> checkIfMealExists(String name) async {
    return name.toLowerCase() == "rice" || name.toLowerCase() == "chicken";
  }

  Future<void> _showCustomDialog({
    required String title,
    required String content,
    required VoidCallback onContinue,
  }) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF4A7BF7),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "No",
              style: TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Continue",
              style: TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      onContinue();
    }
  }

  void _handleUnplannedActivity() {
    _showCustomDialog(
      title: "Unplanned Activity",
      content: "Please provide activity details.",
      onContinue: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
      },
    );
  }

  void _handleUnplannedMeal() {
    _showCustomDialog(
      title: "Planned Activity",
      content: "Please provide activity details.",
      onContinue: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPlateScreen()),
        );
      },
    );
  }

  void _saveLog() {
    setState(() => _isSaving = true);

    final glucose = double.tryParse(glucoseController.text) ?? 0;
    final meal = mealController.text.trim().toLowerCase();
    final Map<String, double> mealCarbs = {
      'rice': 45,
      'chicken': 5,
      'bread': 30,
      'apple': 15,
    };
    final carbs = mealCarbs[meal] ?? 0;
    final dose = calculateDose(glucose, carbs);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF4A7BF7),
        title: const Text(
          "Insulin Dose",
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "The recommended insulin dose is: ${dose.toStringAsFixed(1)} U",
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(fontFamily: 'SfProDisplay', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    setState(() => _isSaving = false);
  }

  Widget _buildLabel(String text, String iconPath) {
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
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'SfProDisplay',
          color: Colors.black54,
        ),
        filled: true,
        fillColor: Colors.grey[300],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontFamily: 'SfProDisplay'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Dose calculator',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            _buildLabel('Pre-meal glucose', 'assets/images/glucose.png'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: glucoseController,
              hintText: 'Enter pre-meal blood sugar',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Image.asset('assets/images/activity.png', height: 20, width: 20),
                const SizedBox(width: 6),
                const Text(
                  'Unplanned activity was done?',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: unplannedActivity,
                  onChanged: (value) {
                    setState(() => unplannedActivity = value!);
                    _handleUnplannedActivity();
                  },
                  fillColor: MaterialStateProperty.all(const Color(0xFF4A7BF7)),
                ),
                const Text('Yes', style: TextStyle(fontFamily: 'SfProDisplay')),
                Radio<bool>(
                  value: false,
                  groupValue: unplannedActivity,
                  onChanged: (value) => setState(() => unplannedActivity = value!),
                ),
                const Text('No', style: TextStyle(fontFamily: 'SfProDisplay')),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabel('What did you eat', 'assets/images/context.png'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: mealController,
              hintText: 'Enter meal name',
            ),
            const SizedBox(height: 24),
            _buildLabel('Planned activity to do?', 'assets/images/plan.png'),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: plannedActivity,
                  onChanged: (value) {
                    setState(() => plannedActivity = value!);
                    _handleUnplannedMeal();
                  },
                  fillColor: MaterialStateProperty.all(const Color(0xFF4A7BF7)),
                ),
                const Text('Yes', style: TextStyle(fontFamily: 'SfProDisplay')),
                Radio<bool>(
                  value: false,
                  groupValue: plannedActivity,
                  onChanged: (value) => setState(() => plannedActivity = value!),
                ),
                const Text('No', style: TextStyle(fontFamily: 'SfProDisplay')),
              ],
            ),
            const SizedBox(height: 30),
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
                        'Calculate dose',
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
    );
  }
}
