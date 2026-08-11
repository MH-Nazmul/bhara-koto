class OverchargeReport {
  const OverchargeReport({
    required this.id,
    required this.busName,
    required this.locationSpot,
    required this.demandedFare,
    required this.officialFare,
    required this.timestamp,
    required this.note,
  });

  final String id;
  final String busName;
  final String locationSpot;
  final double demandedFare;
  final double officialFare;
  final DateTime timestamp;
  final String note;

  double get overchargeAmount => (demandedFare - officialFare).clamp(0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'busName': busName,
        'locationSpot': locationSpot,
        'demandedFare': demandedFare,
        'officialFare': officialFare,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory OverchargeReport.fromJson(Map<String, dynamic> json) => OverchargeReport(
        id: json['id'] as String,
        busName: json['busName'] as String,
        locationSpot: json['locationSpot'] as String,
        demandedFare: (json['demandedFare'] as num).toDouble(),
        officialFare: (json['officialFare'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        note: json['note'] as String? ?? '',
      );
}
