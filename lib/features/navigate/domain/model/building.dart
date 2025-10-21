import 'package:latlong2/latlong.dart';

class Building {
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  Building({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}
