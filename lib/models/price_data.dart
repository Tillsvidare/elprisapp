class PricePoint {
  final double sekPerKwh;
  final double eurPerKwh;
  final double exr;
  final DateTime timeStart;
  final DateTime timeEnd;

  PricePoint({
    required this.sekPerKwh,
    required this.eurPerKwh,
    required this.exr,
    required this.timeStart,
    required this.timeEnd,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      sekPerKwh: json['SEK_per_kWh'].toDouble(),
      eurPerKwh: json['EUR_per_kWh'].toDouble(),
      exr: json['EXR'].toDouble(),
      timeStart: DateTime.parse(json['time_start']),
      timeEnd: DateTime.parse(json['time_end']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SEK_per_kWh': sekPerKwh,
      'EUR_per_kWh': eurPerKwh,
      'EXR': exr,
      'time_start': timeStart.toIso8601String(),
      'time_end': timeEnd.toIso8601String(),
    };
  }

  bool isCurrent() {
    final now = DateTime.now();
    return now.isAfter(timeStart) && now.isBefore(timeEnd);
  }

  String getTimeRange() {
    final startTime = '${timeStart.hour.toString().padLeft(2, '0')}:${timeStart.minute.toString().padLeft(2, '0')}';
    final endTime = '${timeEnd.hour.toString().padLeft(2, '0')}:${timeEnd.minute.toString().padLeft(2, '0')}';
    return '$startTime-$endTime';
  }
}
