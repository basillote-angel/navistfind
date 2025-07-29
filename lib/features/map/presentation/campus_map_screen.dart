import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final LatLng campusCenter = LatLng(7.359209, 125.706379);
  final MapController _mapController = MapController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _selectedBuildingName;

  final List<String> categories = [
    'All',
    'Academic',
    'Administrative',
    'Recreational',
    'Student Services',
    'Service',
    'Health Services',
  ];

  final List<Map<String, dynamic>> buildings = [
    {
      "name": "Library",
      "category": "Academic",
      "description": "Main campus library with study areas and archives.",
      "latLng": LatLng(7.359008, 125.706665),
      "rooms": ["Reading Hall", "Archives", "Research Room"]
    },
    {
      "name": "Admin Building",
      "category": "Administrative",
      "description": "Handles registration, faculty, and IT services.",
      "latLng": LatLng(7.359074, 125.706070),
      "rooms": [
        "Room 101 – Registrar’s Office",
        "Room 102 – Faculty Room",
        "Room 103 – IT Support"
      ]
    },
    {
      "name": "Science Building",
      "category": "Academic",
      "description": "Science classrooms and laboratories.",
      "latLng": LatLng(7.359658, 125.706482),
      "rooms": [
        "Room 201 – Physics Lab",
        "Room 202 – Chemistry Lab",
        "Room 203 – Biology Lab"
      ]
    },
    {
      "name": "Technology Building",
      "category": "Academic",
      "description": "Computer labs and electronics workshops.",
      "latLng": LatLng(7.359392, 125.706595),
      "rooms": [
        "Room 301 – Computer Lab A",
        "Room 302 – Computer Lab B",
        "Room 303 – Robotics Room"
      ]
    },
    {
      "name": "Gymnasium",
      "category": "Recreational",
      "description": "Indoor gym for sports and school events.",
      "latLng": LatLng(7.358104, 125.706301),
      "rooms": ["Main Court", "Locker Room", "Equipment Storage"]
    },
    {
      "name": "Student Center",
      "category": "Student Services",
      "description": "Lounge, guidance, and student organization offices.",
      "latLng": LatLng(7.358355, 125.705738),
      "rooms": [
        "Room 401 – Guidance Office",
        "Room 402 – Student Affairs",
        "Room 403 – Lounge"
      ]
    },
    {
      "name": "Cafeteria",
      "category": "Service",
      "description": "Dining area for students and faculty.",
      "latLng": LatLng(7.358470, 125.706246),
      "rooms": ["Main Dining Area", "Kitchen", "Storage Room"]
    },
    {
      "name": "Senior High Building",
      "category": "Academic",
      "description": "Classrooms for senior high school students.",
      "latLng": LatLng(7.359820, 125.706890),
      "rooms": [
        "Room 501 – Grade 11 STEM",
        "Room 502 – Grade 12 HUMSS",
        "Room 503 – Faculty Lounge"
      ]
    },
    {
      "name": "Clinic",
      "category": "Health Services",
      "description": "Provides basic medical services and first aid.",
      "latLng": LatLng(7.358789, 125.705915),
      "rooms": ["Consultation Room", "First Aid Room", "Pharmacy"]
    },
    {
      "name": "Covered Court",
      "category": "Recreational",
      "description": "Open-air court for events and PE classes.",
      "latLng": LatLng(7.359130, 125.705560),
      "rooms": ["Court Area", "Announcers Booth", "Storage"]
    },
  ];

  List<Map<String, dynamic>> get filteredBuildings {
    return buildings.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b["name"].toLowerCase().contains(_searchQuery) ||
          (b["rooms"] as List).any(
            (room) => room.toLowerCase().contains(_searchQuery),
          );
      final matchesCategory =
          _selectedCategory == 'All' || b["category"] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1C2A40),
          elevation: 2,
          titleSpacing: 12,
          centerTitle: false,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search building',
                        hintStyle: const TextStyle(fontSize: 14),
                        suffixIcon: const Icon(Icons.search, size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });

                        final matches = filteredBuildings;
                        if (matches.length == 1) {
                          final target = matches.first["latLng"] as LatLng;
                          _mapController.move(target, 19);
                          setState(() {
                            _selectedBuildingName = matches.first["name"];
                          });
                        } else {
                          setState(() {
                            _selectedBuildingName = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    dropdownColor: Colors.grey[200],
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    items: categories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _selectedBuildingName = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: campusCenter,
              zoom: 18.0,
              maxZoom: 20,
              minZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_nav_mobile',
              ),
              MarkerLayer(
                markers: filteredBuildings.map((building) {
                  return Marker(
                    width: 150,
                    height: 60,
                    point: building["latLng"],
                    child: Column(
                      children: [
                        Text(
                          building["name"],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            backgroundColor:
                                Colors.white.withOpacity(0.1), // Light label
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _showBuildingInfo(building),
                          child: Icon(
                            Icons.location_on,
                            color: _selectedBuildingName == building["name"]
                                ? Colors.red
                                : Colors.redAccent,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBuildingInfo(Map<String, dynamic> building) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          building["name"],
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(building["description"]),
              const SizedBox(height: 16),
              const Text("Rooms:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(
                building["rooms"].length,
                (index) => Text('• ${building["rooms"][index]}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Navigation started to ${building["name"]}"),
              ));
            },
            child: const Text("Start Navigation"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
