import 'package:flutter/material.dart';

class LogGlucoseScreen extends StatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  State<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends State<LogGlucoseScreen> {
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  TimeOfDay? selectedTime;
  String? selectedContext;
  bool _isSaving = false;

  final List<String> contextOptions = ['Before meal', 'After meal'];

  @override
  void dispose() {
    glucoseController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    await Future.delayed(const Duration(seconds: 2)); // Simulation d'une sauvegarde

    print('Glucose: ${glucoseController.text}');
    print('Time: ${selectedTime!.format(context)}');
    print('Context: $selectedContext');
    print('Note: ${noteController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Glucose log saved')),
    );

    setState(() => _isSaving = false);
  }

  bool _validateInputs() {
    if (glucoseController.text.isEmpty) {
      _showMessage('Please enter glucose value');
      return false;
    }

    if (selectedTime == null) {
      _showMessage('Please select time');
      return false;
    }

    if (selectedContext == null) {
      _showMessage('Please select context');
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7BF7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
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
                      _buildLabel('Glucose Value (mg/dL)', 'assets/images/glucose.png'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: glucoseController,
                        hintText: 'Enter glucose value',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('Time', 'assets/images/last injection.png'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickTime,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            hintText: selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Select time',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('Context', 'assets/images/context.png'),
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
                            onChanged: (newValue) {
                              setState(() => selectedContext = newValue);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('Note', 'assets/images/note.png'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: noteController,
                        hintText: 'Optional note (e.g., stress, heavy meal, etc.)',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
      readOnly: controller == null,
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
    );
  }
}
