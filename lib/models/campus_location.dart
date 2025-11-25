import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final IconData icon;
  final List<String> imagePaths;
  String? panoramaUrl; // Now mutable for dynamic updates

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.icon,
    this.imagePaths = const [],
    this.panoramaUrl,
  });

  // Helper to get main image
  String get mainImage => imagePaths.isNotEmpty
      ? imagePaths[0]
      : 'assets/images/placeholder.jpg';

  // Helper to check if location has gallery images
  bool get hasGallery => imagePaths.length > 1;

  // Helper to check if location has 360° panorama
  bool get hasPanorama => panoramaUrl != null && panoramaUrl!.isNotEmpty;

  // Copy with method for easy updates
  CampusLocation copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    IconData? icon,
    List<String>? imagePaths,
    String? panoramaUrl,
  }) {
    return CampusLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      icon: icon ?? this.icon,
      imagePaths: imagePaths ?? this.imagePaths,
      panoramaUrl: panoramaUrl ?? this.panoramaUrl,
    );
  }

  // Firebase methods
  Map<String, dynamic> toFirebaseJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'iconCodePoint': icon.codePoint,
      'imagePaths': imagePaths,
      'panoramaUrl': panoramaUrl,
    };
  }

  factory CampusLocation.fromFirebaseJson(Map<dynamic, dynamic> json) {
    return CampusLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      imagePaths: (json['imagePaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      panoramaUrl: json['panoramaUrl'] as String?,
    );
  }

  Future<void> uploadAllLocations() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('campus_locations');

    for (var location in CampusLocation.allLocations) {
      await ref.child(location.id).set(location.toFirebaseJson());
      print('Uploaded: ${location.name}');
    }

    print('All campus locations uploaded!');
  }
  // Save panorama URL to Firebase
  static Future<void> savePanoramaUrl(String locationId, String panoramaUrl) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('campus_locations/$locationId');
    await ref.update({
      'panoramaUrl': panoramaUrl,
      'updatedAt': ServerValue.timestamp,
    });
  }

  // Load panorama URL from Firebase
  static Future<String?> loadPanoramaUrl(String locationId) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('campus_locations/$locationId');
    final snapshot = await ref.child('panoramaUrl').get();
    if (snapshot.exists) {
      return snapshot.value as String?;
    }
    return null;
  }

  // Load all locations with their panorama URLs from Firebase
  static Future<Map<String, String>> loadAllPanoramaUrls() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('campus_locations');
    final snapshot = await ref.get();

    final Map<String, String> panoramaUrls = {};
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        if (value is Map && value['panoramaUrl'] != null) {
          panoramaUrls[key.toString()] = value['panoramaUrl'].toString();
        }
      });
    }
    return panoramaUrls;
  }

  static List<CampusLocation> get allLocations => [
    CampusLocation(
      id: 'irc',
      name: 'Aklatang Emilio Aguinaldo - IRC',
      description: 'Main campus library',
      latitude: 14.3208,
      longitude: 120.9619,
      icon: Icons.local_library,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764068383990.jpg',
    ),
    CampusLocation(
      id: 'agh',
      name: 'Ayuntamiento de Gonzales Hall',
      description: 'Administrative building with student services',
      latitude: 14.3205,
      longitude: 120.9633,
      icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764068651651.jpg',
    ),
    CampusLocation(
      id: 'bahay_pagasa',
      name: 'Bahay Pag-asa',
      description: 'Campus Facility',
      latitude: 14.3266,
      longitude: 120.9564,
      icon: Icons.house,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'cso',
      name: 'Campus Security Office',
      description: 'Security Services',
      latitude: 14.3244,
      longitude: 120.9590,
      icon: Icons.security,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'cth_tirona',
      name: 'Candido Tirona Hall (CTH)',
      description: 'Campus Building',
      latitude: 14.3234,
      longitude: 120.9592,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'ceat',
      name: 'CEAT Building',
      description: 'College of Engineering, Architecture & Technology',
      latitude: 14.3230,
      longitude: 120.9584,
      icon: Icons.engineering,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'library',
      name: 'DLSU-D Library',
      description: 'Main campus library with study areas and resources',
      latitude: 14.3208,
      longitude: 120.9619,
      icon: Icons.local_library,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'mah',
      name: 'Doña Marcela De Agoncillo Hall (MAH)',
      description: 'Campus Building',
      latitude: 14.3211,
      longitude: 120.9622,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'fdh',
      name: 'Dr. Del Mundo Hall (FDH)',
      description: 'Campus Building',
      latitude: 14.3202,
      longitude: 120.9628,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'fch',
      name: 'Felipe Calderon Hall (FCH)',
      description: 'Campus Building',
      latitude: 14.3222,
      longitude: 120.9596,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'gate_1',
      name: 'Gate 1',
      description: 'Main entrance to DLSU-D campus',
      latitude: 14.3216,
      longitude: 120.9635,
      icon: Icons.door_front_door,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'gate_3',
      name: 'Gate 3',
      description: 'Secondary entrance near sports complex',
      latitude: 14.3282,
      longitude: 120.9569,
      icon: Icons.door_front_door,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764072159266.jpg',
    ),
    CampusLocation(
      id: 'gdo',
      name: 'GDO/Grandstand and Track Oval',
      description: 'Sports Facility',
      latitude: 14.3252,
      longitude: 120.9581,
      icon: Icons.sports,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'gdh',
      name: 'Gregoria De Jesus Hall (GDH)',
      description: 'Campus Building',
      latitude: 14.3225,
      longitude: 120.9588,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'gmh',
      name: 'Gregoria Montoya Hall (GMH)',
      description: 'Campus Building',
      latitude: 14.3232,
      longitude: 120.9588,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'hotel_rafael',
      name: 'Hotel Rafael/Gourmet Hall/ Centennial Hall',
      description: 'Hotel and Event Venue',
      latitude: 14.3222,
      longitude: 120.9617,
      icon: Icons.hotel,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069300301.jpg',
    ),
    CampusLocation(
      id: 'ictc',
      name: 'Information and Communications Technology Center (ICTC)',
      description: 'IT Services',
      latitude: 14.3223,
      longitude: 120.9629,
      icon: Icons.computer,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069172201.jpg',
    ),
    CampusLocation(
      id: 'jfh',
      name: 'Julian Felipe Hall',
      description: 'Main academic building with classrooms and faculty offices',
      latitude: 14.3211,
      longitude: 120.9626,
      icon: Icons.school,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069533901.jpg',
    ),
    CampusLocation(
      id: 'kabalikat',
      name: 'Kabalikat ng DLSU-D',
      description: 'Office',
      latitude: 14.3236,
      longitude: 120.9597,
      icon: Icons.group_work,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'ldh',
      name: 'Ladislao Diwa Hall (LDH)',
      description: 'Campus Building',
      latitude: 14.3225,
      longitude: 120.9597,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'cafeteria',
      name: 'Main Cafeteria',
      description: 'Campus dining facility with various food options',
      latitude: 14.3275,
      longitude: 120.9392,
      icon: Icons.restaurant,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'dormitories',
      name: 'Male and Female Dormitories',
      description: 'Student Residences',
      latitude: 14.3210,
      longitude: 120.9600,
      icon: Icons.night_shelter,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069668378.jpg',
    ),
    CampusLocation(
      id: 'mlh',
      name: 'Maria Salome Lianera Hall (MLH)',
      description: 'Campus Building',
      latitude: 14.3237,
      longitude: 120.9582,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'malvarez',
      name: 'Mariano Alvarez Hall',
      description: 'Campus Building',
      latitude: 14.3218,
      longitude: 120.9630,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'mth',
      name: 'Mariano Trias Hall (MTH)',
      description: 'Campus Building',
      latitude: 14.3237,
      longitude: 120.9587,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'museo',
      name: 'Museo De La Salle/Camarin',
      description: 'University Museum',
      latitude: 14.3210,
      longitude: 120.9610,
      icon: Icons.museum,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070148168.jpg',
    ),
    CampusLocation(
      id: 'polca',
      name: 'Parents Organization of La Salle Cavite (POLCA)',
      description: 'Office',
      latitude: 14.3222,
      longitude: 120.9599,
      icon: Icons.group,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'pch',
      name: 'Paulo Campos Hall (PCH)',
      description: 'Campus Building',
      latitude: 14.3209,
      longitude: 120.9628,
      icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070251665.jpg',
    ),
    CampusLocation(
      id: 'pbh',
      name: 'Purificacion Borromeo Hall (PBH)',
      description: 'Campus Building',
      latitude: 14.3210,
      longitude: 120.9626,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'residencia',
      name: 'Residencia De San Miguel',
      description: 'Campus Building',
      latitude: 14.3203,
      longitude: 120.9619,
      icon: Icons.home,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'rcc',
      name: 'Retreat and Conference Center',
      description: 'Event Venue',
      latitude: 14.3275,
      longitude: 120.9567,
      icon: Icons.meeting_room,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070441634.jpg',
    ),
    CampusLocation(
      id: 'sah',
      name: 'Santiago Alvarez Hall (SAH)',
      description: 'Campus Building',
      latitude: 14.3232,
      longitude: 120.9583,
      icon: Icons.business,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'sdah',
      name: 'Severino De Las Alas Hall',
      description: 'Campus Building',
      latitude: 14.3227,
      longitude: 120.9610,
      icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070549881.jpg',
    ),
    CampusLocation(
      id: 'uls',
      name: 'Ugnayang La Salle',
      description: 'University multi-purpose sports complex',
      latitude: 14.3269,
      longitude: 120.9573,
      icon: Icons.sports_basketball,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070665707.jpg',
    ),
    CampusLocation(
      id: 'chapel',
      name: 'University Chapel',
      description: 'A quiet place for reflection and prayer',
      latitude: 14.3260,
      longitude: 120.9592,
      icon: Icons.church,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070740605.jpg',
    ),
    CampusLocation(
      id: 'food_square',
      name: 'University Food Square',
      description: 'Dining Area',
      latitude: 14.3215,
      longitude: 120.9601,
      icon: Icons.fastfood,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'vbh',
      name: 'Vito Belarmino Hall (VBH)',
      description: 'Campus Building',
      latitude: 14.3221,
      longitude: 120.9592,
      icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070929424.jpg',
    ),
    CampusLocation(
      id: 'cafe_museo',
      name: 'Cafe Museo',
      description: 'Dining Area',
      latitude: 14.3212,
      longitude: 120.9609,
      icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071255247.jpg',
    ),
    CampusLocation(
      id: 'cos_classroom_bldg',
      name: 'COS Classroom Building',
      description: 'Dining Area',
      latitude: 14.3202,
      longitude: 120.9628,
      icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071324007.jpg',
    ),
    CampusLocation(
      id: 'milas_diner',
      name: 'Milas Diner',
      description: 'Dining Area',
      latitude: 14.3213,
      longitude: 120.9621,
      icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071386038.jpg',
    ),
    CampusLocation(
      id: 'lcdc',
      name: 'Lasallian Community Development Center',
      description: 'Dining Area',
      latitude: 14.3211,
      longitude: 120.9622,
      icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071456807.jpg',
    ),
    CampusLocation(
      id: 'pool',
      name: 'Swimming Pool',
      description: 'pool',
      latitude: 14.3267,
      longitude: 120.9568,
      icon: Icons.fastfood,
      panoramaUrl:'',
    ),
    CampusLocation(
      id: 'cbaa',
      name: 'College of Business Administration and Accountacy',
      description: 'Dining Area',
      latitude: 14.3238,
      longitude: 120.9582,
      icon: Icons.fastfood,
      panoramaUrl:'',
    ),
  ];
}