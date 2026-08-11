class BusStop {
  const BusStop({
    required this.nameEn,
    required this.nameBn,
    required this.latitude,
    required this.longitude,
    required this.kmFromStart,
  });

  final String nameEn;
  final String nameBn;
  final double latitude;
  final double longitude;
  final double kmFromStart;
}

class BusRoute {
  const BusRoute({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.stops,
  });

  final String id;
  final String nameEn;
  final String nameBn;
  final List<BusStop> stops;

  static const List<BusRoute> presetRoutes = [
    BusRoute(
      id: 'uttara_motijheel',
      nameEn: 'Uttara House Building ➔ Motijheel',
      nameBn: 'উত্তরা হাউজ বিল্ডিং ➔ মতিঝিল',
      stops: [
        BusStop(nameEn: 'Uttara House Building', nameBn: 'উত্তরা হাউজ বিল্ডিং', latitude: 23.8748, longitude: 90.3984, kmFromStart: 0.0),
        BusStop(nameEn: 'Airport', nameBn: 'বিমানবন্দর', latitude: 23.8514, longitude: 90.4079, kmFromStart: 3.2),
        BusStop(nameEn: 'Khilkhet', nameBn: 'খিলক্ষেত', latitude: 23.8291, longitude: 90.4184, kmFromStart: 6.0),
        BusStop(nameEn: 'Mohakhali', nameBn: 'মহাখালী', latitude: 23.7779, longitude: 90.4046, kmFromStart: 12.5),
        BusStop(nameEn: 'Farmgate', nameBn: 'ফার্মগেট', latitude: 23.7561, longitude: 90.3872, kmFromStart: 15.8),
        BusStop(nameEn: 'Shahbagh', nameBn: 'শাহবাগ', latitude: 23.7388, longitude: 90.3957, kmFromStart: 18.2),
        BusStop(nameEn: 'Press Club', nameBn: 'প্রেস ক্লাব', latitude: 23.7291, longitude: 90.4071, kmFromStart: 19.8),
        BusStop(nameEn: 'Motijheel / GPO', nameBn: 'মতিঝিল / জিপিও', latitude: 23.7258, longitude: 90.4150, kmFromStart: 21.0),
      ],
    ),
    BusRoute(
      id: 'mirpur12_motijheel',
      nameEn: 'Mirpur 12 ➔ Shahbagh ➔ Motijheel',
      nameBn: 'মিরপুর ১২ ➔ শাহবাগ ➔ মতিঝিল',
      stops: [
        BusStop(nameEn: 'Mirpur 12', nameBn: 'মিরপুর ১২', latitude: 23.8242, longitude: 90.3654, kmFromStart: 0.0),
        BusStop(nameEn: 'Mirpur 10', nameBn: 'মিরপুর ১০', latitude: 23.8069, longitude: 90.3687, kmFromStart: 2.1),
        BusStop(nameEn: 'Kazipara', nameBn: 'কাজীসিপাড়া', latitude: 23.7972, longitude: 90.3721, kmFromStart: 3.5),
        BusStop(nameEn: 'Shewrapara', nameBn: 'শেওড়াপাড়া', latitude: 23.7891, longitude: 90.3752, kmFromStart: 4.8),
        BusStop(nameEn: 'Agargaon', nameBn: 'আগারগাঁও', latitude: 23.7768, longitude: 90.3789, kmFromStart: 6.5),
        BusStop(nameEn: 'Farmgate', nameBn: 'ফার্মগেট', latitude: 23.7561, longitude: 90.3872, kmFromStart: 9.3),
        BusStop(nameEn: 'Kawran Bazar', nameBn: 'কারওয়ান বাজার', latitude: 23.7505, longitude: 90.3921, kmFromStart: 10.4),
        BusStop(nameEn: 'Shahbagh', nameBn: 'শাহবাগ', latitude: 23.7388, longitude: 90.3957, kmFromStart: 12.0),
        BusStop(nameEn: 'Press Club', nameBn: 'প্রেস ক্লাব', latitude: 23.7291, longitude: 90.4071, kmFromStart: 13.6),
        BusStop(nameEn: 'Motijheel', nameBn: 'মতিঝিল', latitude: 23.7258, longitude: 90.4150, kmFromStart: 14.8),
      ],
    ),
    BusRoute(
      id: 'nabinagar_sayedabad',
      nameEn: 'Nabinagar ➔ Gabtoli ➔ Sayedabad',
      nameBn: 'নবীনগর ➔ গাবতলী ➔ সায়েদাবাদ',
      stops: [
        BusStop(nameEn: 'Nabinagar', nameBn: 'নবীনগর', latitude: 23.9102, longitude: 90.2582, kmFromStart: 0.0),
        BusStop(nameEn: 'Savar Bus Stand', nameBn: 'সাভার বাস স্ট্যান্ড', latitude: 23.8471, longitude: 90.2574, kmFromStart: 8.5),
        BusStop(nameEn: 'Hemayetpur', nameBn: 'হেমায়েতপুর', latitude: 23.7915, longitude: 90.2721, kmFromStart: 15.2),
        BusStop(nameEn: 'Gabtoli', nameBn: 'গাবতলী', latitude: 23.7831, longitude: 90.3421, kmFromStart: 23.0),
        BusStop(nameEn: 'Technical', nameBn: 'টেকনিক্যাল', latitude: 23.7812, longitude: 90.3541, kmFromStart: 24.5),
        BusStop(nameEn: 'Shyamoli', nameBn: 'শ্যামলী', latitude: 23.7725, longitude: 90.3662, kmFromStart: 26.2),
        BusStop(nameEn: 'Science Lab', nameBn: 'সায়েন্স ল্যাব', latitude: 23.7381, longitude: 90.3842, kmFromStart: 30.5),
        BusStop(nameEn: 'Shahbagh', nameBn: 'শাহবাগ', latitude: 23.7388, longitude: 90.3957, kmFromStart: 32.1),
        BusStop(nameEn: 'Motijheel', nameBn: 'মতিঝিল', latitude: 23.7258, longitude: 90.4150, kmFromStart: 34.8),
        BusStop(nameEn: 'Sayedabad', nameBn: 'সায়েদাবাদ', latitude: 23.7142, longitude: 90.4281, kmFromStart: 37.2),
      ],
    ),
  ];
}
