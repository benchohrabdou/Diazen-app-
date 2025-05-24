import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoseResultScreen extends StatefulWidget {
  final double dose;
  final double? glucoseLevel;
  final double? carbAmount;
  final double? correctionDose;
  final double? mealDose;
  final double? activityReduction;
  final double? activityReductionUnits;
  final double? activityReductionPercent;
  final String? mealName;
  final double? unplannedActivityCalories;
  final double? plannedActivityCalories;
  final double? adjustedCarbAmount;

  const DoseResultScreen({
    Key? key,
    required this.dose,
    this.glucoseLevel,
    this.carbAmount,
    this.correctionDose,
    this.mealDose,
    this.activityReduction,
    this.activityReductionUnits,
    this.activityReductionPercent,
    this.mealName,
    this.unplannedActivityCalories,
    this.plannedActivityCalories,
    this.adjustedCarbAmount,
  }) : super(key: key);

  @override
  State<DoseResultScreen> createState() => _DoseResultScreenState();
}

class _DoseResultScreenState extends State<DoseResultScreen> {
  bool _isSaving = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Dose Result',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7BF7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4A7BF7).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your insulin dose is',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${widget.dose.toInt()} units',
                              style: const TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A7BF7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Calculation breakdown
                      if (widget.glucoseLevel != null && widget.adjustedCarbAmount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Calculation Breakdown',
                                  style: TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Meal information
                                if (widget.mealName != null)
                                  _buildCalculationRow(
                                    'Meal',
                                    widget.mealName!,
                                  ),

                                // Unplanned Activity Calories (if present)
                                if (widget.unplannedActivityCalories != null && widget.unplannedActivityCalories! > 0)
                                  _buildCalculationRow(
                                    'Unplanned Activity',
                                    '${widget.unplannedActivityCalories!.toStringAsFixed(0)} kcal',
                                  ),

                                // Planned Activity Calories (if present)
                                if (widget.plannedActivityCalories != null && widget.plannedActivityCalories! > 0)
                                  _buildCalculationRow(
                                    'Planned Activity',
                                    '${widget.plannedActivityCalories!.toStringAsFixed(0)} kcal',
                                  ),

                                // Glucose level
                                if (widget.glucoseLevel != null)
                                  _buildCalculationRow(
                                    'Blood Glucose',
                                    '${widget.glucoseLevel!.toInt()} mg/dL',
                                  ),

                                // Total Carb amount
                                if (widget.adjustedCarbAmount != null)
                                  _buildCalculationRow(
                                    'Total Carbs',
                                    '${widget.adjustedCarbAmount!.toStringAsFixed(1)} g',
                                  ),

                                const Divider(height: 30),

                                // Meal dose
                                if (widget.mealDose != null)
                                  _buildCalculationRow(
                                    'Meal Dose',
                                    '${widget.mealDose!.toStringAsFixed(1)} units',
                                    details: 'Carbs ÷ ICR',
                                  ),

                                // Correction dose
                                if (widget.correctionDose != null)
                                  _buildCalculationRow(
                                    'Correction Dose',
                                    '${widget.correctionDose!.toStringAsFixed(1)} units',
                                    details: '(Glucose - Target) ÷ ISF',
                                  ),

                                // Activity reduction in units (if present)
                                if (widget.activityReductionUnits != null &&
                                    widget.activityReductionUnits! > 0)
                                  _buildCalculationRow(
                                    'Activity Reduction',
                                    '-${widget.activityReductionUnits?.toStringAsFixed(2) ?? '0.00'} units',
                                    details: (widget.activityReductionPercent != null &&
                                            widget.activityReductionPercent! > 0)
                                        ? '${widget.activityReductionPercent?.toStringAsFixed(0) ?? '0'}% reduction'
                                        : null,
                                  ),
                                // Always show the percentage row (even if 0)
                                if (widget.activityReductionPercent != null)
                                  _buildCalculationRow(
                                    'Activity Reduction Percentage',
                                    '${widget.activityReductionPercent?.toStringAsFixed(0) ?? '0'}%',
                                  ),

                                const Divider(height: 30),

                                // Total dose
                                _buildCalculationRow(
                                  'Total Dose',
                                  '${widget.dose.toInt()} units',
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20), // Spacing before the button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7BF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SfProDisplay',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Spacing after the button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value,
      {String? details, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? const Color(0xFF4A7BF7) : Colors.black87,
                ),
              ),
              if (details != null)
                Text(
                  details,
                  style: const TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SfProDisplay',
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF4A7BF7) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
