import 'fare_config.dart';

class LatLngPoint {
  const LatLngPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
      };

  factory LatLngPoint.fromJson(Map<String, dynamic> json) => LatLngPoint(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
}

class TripHistoryItem {
  const TripHistoryItem({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.fareTotal,
    required this.profile,
    required this.routePoints,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceMeters;
  final double fareTotal;
  final FareProfile profile;
  final List<LatLngPoint> routePoints;

  Duration get duration => endedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'distanceMeters': distanceMeters,
        'fareTotal': fareTotal,
        'profile': profile.key,
        'routePoints': routePoints.map((p) => p.toJson()).toList(),
      };

  factory TripHistoryItem.fromJson(Map<String, dynamic> json) => TripHistoryItem(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: DateTime.parse(json['endedAt'] as String),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        fareTotal: (json['fareTotal'] as num).toDouble(),
        profile: FareProfile.fromKey(json['profile'] as String?),
        routePoints: (json['routePoints'] as List<dynamic>?)
                ?.map((e) => LatLngPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
