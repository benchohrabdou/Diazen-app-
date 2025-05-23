class GlucoseLog {
  final String glucose;
  final String time;
  final String context;
  final String? note;
  final double? dose;

  GlucoseLog({
    required this.glucose,
    required this.time,
    required this.context,
    this.note,
    this.dose,
  });

  factory GlucoseLog.fromJson(Map<String, dynamic> json) {
    return GlucoseLog(
      glucose: json['glucose'],
      time: json['time'],
      context: json['context'],
      note: json['note'],
      dose: json['dose'] != null ? (json['dose'] as num).toDouble() : null,
    );
  }
}
