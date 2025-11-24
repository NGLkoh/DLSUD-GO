import 'package:flutter/material.dart';

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final IconData icon;

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.icon,
  });

  static List<CampusLocation> get allLocations => [
        CampusLocation(
          id: 'gate_1',
          name: 'Gate 1',
          description: 'Main entrance to DLSU-D campus',
          latitude: 14.3308,
          longitude: 120.9378,
          icon: Icons.door_front_door,
        ),
        CampusLocation(
          id: 'gate_3',
          name: 'Gate 3',
          description: 'Secondary entrance near sports complex',
          latitude: 14.3262,
          longitude: 120.9405,
          icon: Icons.door_front_door,
        ),
        CampusLocation(
          id: 'jfh',
          name: 'Julian Felipe Hall',
          description: 'Main academic building with classrooms and faculty offices',
          latitude: 14.3295,
          longitude: 120.9385,
          icon: Icons.school,
        ),
        CampusLocation(
          id: 'agh',
          name: 'Ayuntamiento de Gonzales Hall',
          description: 'Administrative building with student services',
          latitude: 14.3289,
          longitude: 120.9382,
          icon: Icons.business,
        ),
        CampusLocation(
          id: 'library',
          name: 'DLSU-D Library',
          description: 'Main campus library with study areas and resources',
          latitude: 14.3283,
          longitude: 120.9388,
          icon: Icons.local_library,
        ),
        CampusLocation(
          id: 'cafeteria',
          name: 'Main Cafeteria',
          description: 'Campus dining facility with various food options',
          latitude: 14.3275,
          longitude: 120.9392,
          icon: Icons.restaurant,
        ),
        CampusLocation(
          id: 'uls',
          name: 'Ugnayang La Salle',
          description: 'University multi-purpose sports complex',
          latitude: 14.3269,
          longitude: 120.9405,
          icon: Icons.sports_basketball,
        ),
        CampusLocation(
          id: 'chapel',
          name: 'University Chapel',
          description: 'A quiet place for reflection and prayer',
          latitude: 14.3299,
          longitude: 120.9380,
          icon: Icons.church,
        ),
        CampusLocation(
          id: 'ceat',
          name: 'CEAT Building',
          description: 'College of Engineering, Architecture & Technology',
          latitude: 14.3280,
          longitude: 120.9375,
          icon: Icons.engineering,
        ),
      ];
}
