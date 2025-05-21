import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CustomCard({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
  color: Color.fromARGB(207, 74, 123, 247),
  borderRadius: BorderRadius.circular(20), // Choisis un seul radius
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.2),
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ],
),

        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
