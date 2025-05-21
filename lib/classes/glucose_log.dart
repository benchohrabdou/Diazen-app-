class GlucoseLog {
  final String glucose;
  final String time;
  final String context;
  final String? note;

  GlucoseLog({
    required this.glucose,
    required this.time,
    required this.context,
    this.note,
  });

  factory GlucoseLog.fromJson(Map<String, dynamic> json) {
    return GlucoseLog(
      glucose: json['glucose'],
      time: json['time'],
      context: json['context'],
      note: json['note'],
    );
  }
}