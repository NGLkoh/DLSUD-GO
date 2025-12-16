// lib/models/campus_location.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// 1. Define the Sections
enum CampusSection {
  east,
  west,
}

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final IconData icon;
  final List<String> imagePaths;
  String? panoramaUrl;
  final CampusSection section; // 2. Add Section Property

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.icon,
    required this.section, // Required now
    this.imagePaths = const [],
    this.panoramaUrl,
  });

  String get mainImage => imagePaths.isNotEmpty
      ? imagePaths[0]
      : 'assets/images/placeholder.jpg';

  bool get hasGallery => imagePaths.length > 1;
  bool get hasPanorama => panoramaUrl != null && panoramaUrl!.isNotEmpty;

  // Helper to get display name of section
  String get sectionName {
    return section == CampusSection.east ? "East Campus" : "West Campus";
  }

  CampusLocation copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    IconData? icon,
    List<String>? imagePaths,
    String? panoramaUrl,
    CampusSection? section,
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
      section: section ?? this.section,
    );
  }

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
      'section': section.index, // Save as integer (0=east, 1=west)
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
      section: CampusSection.values[json['section'] as int? ?? 0], // Default to East if missing
    );
  }

  // ... (Upload/Load methods remain the same) ...
  Future<void> uploadAllLocations() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('campus_locations');
    for (var location in CampusLocation.allLocations) {
      await ref.child(location.id).set(location.toFirebaseJson());
    }
  }

  static Future<void> savePanoramaUrl(String locationId, String panoramaUrl) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('campus_locations/$locationId');
    await ref.update({'panoramaUrl': panoramaUrl});
  }

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
      id: 'east_jfh_clinic',
      name: 'East JFH Clinic',
      description: 'Medical Clinic (East)',
      section: CampusSection.east,
      latitude: 14.3228, longitude: 120.9589, icon: Icons.medical_services,
    ),
    CampusLocation(
      id: 'agh',
      name: 'Ayuntamiento de Gonzales Hall',
      description: 'Administrative building',
      section: CampusSection.east,
      latitude: 14.3205, longitude: 120.9633, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764068651651.jpg',
    ),
    CampusLocation(
      id: 'irc',
      name: 'Aklatang Emilio Aguinaldo - IRC',
      description: 'Main campus library',
      section: CampusSection.east,
      latitude: 14.3208, longitude: 120.9619, icon: Icons.local_library,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764068383990.jpg',
    ),
    CampusLocation(
      id: 'botanical_garden',
      name: 'Botanical Garden',
      description: 'Nature area',
      section: CampusSection.east,
      latitude: 14.3217, longitude: 120.9617, icon: Icons.nature,
    ),
    CampusLocation(
      id: 'cultural_heritage_complex',
      name: 'Br. Gus Boquer, FSC Cultural Heritage Complex',
      description: 'Cultural Center',
      section: CampusSection.east,
      latitude: 14.3211, longitude: 120.9613, icon: Icons.museum,
    ),
    CampusLocation(
      id: 'cafe_museo',
      name: 'Cafe Museo',
      description: 'Dining Area',
      section: CampusSection.east,
      latitude: 14.3212, longitude: 120.9609, icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071255247.jpg',
    ),
    CampusLocation(
      id: 'museo',
      name: 'Museo De La Salle/Camarin',
      description: 'University Museum',
      section: CampusSection.east,
      latitude: 14.3210, longitude: 120.9610, icon: Icons.museum,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070148168.jpg',
    ),
    CampusLocation(
      id: 'cos_classroom_bldg',
      name: 'College of Science (COS)',
      description: 'Academic Building',
      section: CampusSection.east,
      latitude: 14.3202, longitude: 120.9628, icon: Icons.science,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071324007.jpg',
    ),
    CampusLocation(
      id: 'mah',
      name: 'Doña Marcela De Agoncillo Hall (MAH)',
      description: 'Campus Building',
      section: CampusSection.east,
      latitude: 14.3211, longitude: 120.9622, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764083895940.jpg',
    ),
    CampusLocation(
      id: 'fdh',
      name: 'Dr. Del Mundo Hall (FDH)',
      description: 'Campus Building',
      section: CampusSection.east,
      latitude: 14.3202, longitude: 120.9628, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764081220591.jpg',
    ),
    CampusLocation(
      id: 'gate_1',
      name: 'Magdalo Gate (Gate 1)',
      description: 'Main entrance',
      section: CampusSection.east,
      latitude: 14.3216, longitude: 120.9635, icon: Icons.door_front_door,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764081152365.jpg',
    ),
    CampusLocation(
      id: 'gate_2',
      name: 'Magpuri Gate (Gate 2)',
      description: 'Campus Gate',
      section: CampusSection.east,
      latitude: 0.0, longitude: 0.0, icon: Icons.door_front_door,
    ),
    CampusLocation(
      id: 'gate_4',
      name: 'Magtagumpay Gate (Gate 4)',
      description: 'Campus Gate',
      section: CampusSection.east,
      latitude: 14.3204, longitude: 120.9635, icon: Icons.door_front_door,
    ),
    CampusLocation(
      id: 'gate_1_rotunda',
      name: 'Gate 1 Rotunda',
      description: 'Landmark',
      section: CampusSection.east,
      latitude: 14.3225, longitude: 120.9633, icon: Icons.crop_square,
    ),
    CampusLocation(
      id: 'hotel_rafael',
      name: 'Hotel Rafael/Gourmet Hall/ Centennial Hall',
      description: 'Hotel and Event Venue',
      section: CampusSection.east,
      latitude: 14.3222, longitude: 120.9617, icon: Icons.hotel,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069300301.jpg',
    ),
    CampusLocation(
      id: 'ictc',
      name: 'Information and Communications Technology Center (ICTC)',
      description: 'IT Services',
      section: CampusSection.east,
      latitude: 14.3223, longitude: 120.9629, icon: Icons.computer,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069172201.jpg',
    ),
    CampusLocation(
      id: 'jfh',
      name: 'Julian Felipe Hall (JFH)',
      description: 'Academic building',
      section: CampusSection.east,
      latitude: 14.3211, longitude: 120.9626, icon: Icons.school,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069533901.jpg',
    ),
    CampusLocation(
      id: 'tjf',
      name: 'Tanghalang Julian Felipe (TJF)',
      description: 'Theater',
      section: CampusSection.east,
      latitude: 14.3211, longitude: 120.9624, icon: Icons.theater_comedy,
    ),
    CampusLocation(
      id: 'porteria_benildo',
      name: 'La Portería de San Benildo',
      description: 'Entry Point',
      section: CampusSection.east,
      latitude: 14.3224, longitude: 120.9633, icon: Icons.door_front_door,
    ),
    CampusLocation(
      id: 'lake_park',
      name: 'Lake Park',
      description: 'Park area',
      section: CampusSection.east,
      latitude: 14.3218, longitude: 120.9603, icon: Icons.park,
    ),
    CampusLocation(
      id: 'lcdc',
      name: 'Lasallian Community Development Center',
      description: 'Dining Area',
      section: CampusSection.east,
      latitude: 14.3211, longitude: 120.9622, icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071456807.jpg',
    ),
    CampusLocation(
      id: 'lumina_bridge',
      name: 'Lumina Bridge',
      description: 'Bridge',
      section: CampusSection.east,
      latitude: 14.3220, longitude: 120.9613, icon: Icons.landscape,
    ),
    CampusLocation(
      id: 'dormitories',
      name: 'Male and Female Dormitories',
      description: 'Student Residences',
      section: CampusSection.east,
      latitude: 14.3210, longitude: 120.9600, icon: Icons.night_shelter,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764069668378.jpg',
    ),
    CampusLocation(
      id: 'malvarez',
      name: 'Mariano Alvarez Hall (MAH) – BFMO',
      description: 'Campus Building',
      section: CampusSection.east,
      latitude: 14.3218, longitude: 120.9630, icon: Icons.business,
    ),
    CampusLocation(
      id: 'milas_diner',
      name: 'Milas Diner',
      description: 'Dining Area',
      section: CampusSection.east,
      latitude: 14.3213, longitude: 120.9621, icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764071386038.jpg',
    ),
    CampusLocation(
      id: 'national_book_store',
      name: 'National Book Store',
      description: 'East Campus branch',
      section: CampusSection.east,
      latitude: 14.3214, longitude: 120.9622, icon: Icons.book,
    ),
    CampusLocation(
      id: 'pgh',
      name: 'Pantaleon Garcia Hall (PGH) – ROTC',
      description: 'ROTC Office',
      section: CampusSection.east,
      latitude: 14.3251, longitude: 120.9574, icon: Icons.military_tech,
    ),
    CampusLocation(
      id: 'pch',
      name: 'Paulo Campos Hall (PCH)',
      description: 'Campus Building',
      section: CampusSection.east,
      latitude: 14.3209, longitude: 120.9628, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070251665.jpg',
    ),
    CampusLocation(
      id: 'pbh',
      name: 'Purificacion Q. Borromeo Hall (PBH)',
      description: 'Campus Building',
      section: CampusSection.east,
      latitude: 14.3210, longitude: 120.9626, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764083316350.jpg',
    ),
    CampusLocation(
      id: 'residencia',
      name: 'Residencia De San Miguel',
      description: 'Campus Building',
      section: CampusSection.east,
      latitude: 14.3203, longitude: 120.9619, icon: Icons.home,
    ),
    CampusLocation(
      id: 'sdah',
      name: 'Severino de las Alas Hall (Alumni)',
      description: 'Alumni Building',
      section: CampusSection.east,
      latitude: 14.3227, longitude: 120.9610, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070549881.jpg',
    ),
    CampusLocation(
      id: 'study_shed',
      name: 'Study Shed',
      description: 'Outdoor Study Area',
      section: CampusSection.east,
      latitude: 14.3214, longitude: 120.9628, icon: Icons.menu_book,
    ),
    CampusLocation(
      id: 'university_lake',
      name: 'University Lake',
      description: 'Campus Lake',
      section: CampusSection.east,
      latitude: 14.3219, longitude: 120.9608, icon: Icons.water,
    ),
    CampusLocation(
      id: 'west_gmh_clinic',
      name: 'West GMH Clinic',
      description: 'Medical Clinic (West)',
      section: CampusSection.west,
      latitude: 14.3210, longitude: 120.9626, icon: Icons.medical_services,
    ),
    CampusLocation(
      id: 'bahay_pagasa',
      name: 'Bahay Pag-asa Dasmariñas',
      description: 'Campus Facility',
      section: CampusSection.west,
      latitude: 14.3266, longitude: 120.9564, icon: Icons.house,
    ),
    CampusLocation(
      id: 'batibot',
      name: 'Batibot',
      description: 'Campus Landmark',
      section: CampusSection.west,
      latitude: 14.3218, longitude: 120.9597, icon: Icons.park,
    ),
    CampusLocation(
      id: 'cso',
      name: 'Campus Security Office',
      description: 'Security Services',
      section: CampusSection.west,
      latitude: 14.3244, longitude: 120.9590, icon: Icons.security,
    ),
    CampusLocation(
      id: 'sustainability_office',
      name: 'Campus Sustainability Office (CSO)',
      description: 'Environmental office',
      section: CampusSection.west,
      latitude: 14.3231, longitude: 120.9582, icon: Icons.eco,
    ),
    CampusLocation(
      id: 'cth_tirona',
      name: 'Candido Tirona Hall (CTH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3234, longitude: 120.9592, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764082533768.jpg',
    ),
    CampusLocation(
      id: 'ceat', // Often considered West/Central
      name: 'CEAT Building',
      description: 'College of Engineering',
      section: CampusSection.west,
      latitude: 14.3230, longitude: 120.9584, icon: Icons.engineering,
    ),
    CampusLocation(
      id: 'cbaa',
      name: 'College of Business Administration (CBA-GSB)',
      description: 'Graduate School Building',
      section: CampusSection.west,
      latitude: 14.3238, longitude: 120.9582, icon: Icons.school,
    ),
    CampusLocation(
      id: 'fch',
      name: 'Felipe Calderon Hall (FCH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3222, longitude: 120.9596, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764082417471.jpg',
    ),
    CampusLocation(
      id: 'gdo',
      name: 'Grandstand & Track Oval',
      description: 'Sports Facility',
      section: CampusSection.west,
      latitude: 14.3252, longitude: 120.9581, icon: Icons.sports,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764082330252.jpg',
    ),
    CampusLocation(
      id: 'gdh',
      name: 'Gregoria De Jesus Hall',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3225, longitude: 120.9588, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764082137124.jpg',
    ),
    CampusLocation(
      id: 'gmh',
      name: 'Gregoria Montoya Hall (GMH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3232, longitude: 120.9588, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764083540402.jpg',
    ),
    CampusLocation(
      id: 'shs_complex',
      name: 'High School Complex (SHS)',
      description: 'Senior High Facilities',
      section: CampusSection.west,
      latitude: 14.3255, longitude: 120.9589, icon: Icons.school,
    ),
    CampusLocation(
      id: 'kabalikat',
      name: 'Kabalikat ng DLSU-D',
      description: 'Community Office',
      section: CampusSection.west,
      latitude: 14.3235, longitude: 120.9602, icon: Icons.group,
    ),
    CampusLocation(
      id: 'ldh',
      name: 'Ladislao Diwa Hall (LDH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3225, longitude: 120.9597, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764082012129.jpg',
    ),
    CampusLocation(
      id: 'gate_3',
      name: 'Magdiwang Gate (Gate 3)',
      description: 'Sports complex entrance',
      section: CampusSection.west,
      latitude: 14.3282, longitude: 120.9569, icon: Icons.door_front_door,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764072159266.jpg',
    ),
    CampusLocation(
      id: 'gate_3_rotunda',
      name: 'Gate 3 Rotunda',
      description: 'Landmark',
      section: CampusSection.west,
      latitude: 14.3280, longitude: 120.9569, icon: Icons.crop_square,
    ),
    CampusLocation(
      id: 'cafeteria',
      name: 'Main Cafeteria',
      description: 'Main Dining',
      section: CampusSection.west, // Located near West
      latitude: 14.3275, longitude: 120.9392, icon: Icons.restaurant,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764083659802.jpg',
    ),
    CampusLocation(
      id: 'mlh',
      name: 'Maria Salome Lianera Hall',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3237, longitude: 120.9582, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764082474526.jpg',
    ),
    CampusLocation(
      id: 'mth',
      name: 'Mariano Trias Hall (MTH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3237, longitude: 120.9587, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764081559845.jpg',
    ),
    CampusLocation(
      id: 'mth_court',
      name: 'MTH Covered Court',
      description: 'Sports Court',
      section: CampusSection.west,
      latitude: 14.3234, longitude: 120.9588, icon: Icons.sports,
    ),
    CampusLocation(
      id: 'pool',
      name: 'Olympic Swimming Pool',
      description: 'Sports Facility',
      section: CampusSection.west,
      latitude: 14.3267, longitude: 120.9568, icon: Icons.pool,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764081924119.jpg',
    ),
    CampusLocation(
      id: 'polca',
      name: 'Parents Organization (POLCA)',
      description: 'Office',
      section: CampusSection.west,
      latitude: 14.3222, longitude: 120.9599, icon: Icons.group,
    ),
    CampusLocation(
      id: 'rcc',
      name: 'Retreat and Conference Center (RCC)',
      description: 'Event Venue',
      section: CampusSection.west,
      latitude: 14.3275, longitude: 120.9567, icon: Icons.meeting_room,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070441634.jpg',
    ),
    CampusLocation(
      id: 'sah',
      name: 'Santiago Alvarez Hall (SAH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3232, longitude: 120.9583, icon: Icons.business,
    ),
    CampusLocation(
      id: 'uls',
      name: 'Ugnayang La Salle (ULS)',
      description: 'Sports Complex',
      section: CampusSection.west,
      latitude: 14.3269, longitude: 120.9573, icon: Icons.sports_basketball,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070665707.jpg',
    ),
    CampusLocation(
      id: 'chapel',
      name: 'University Chapel',
      description: 'Prayer Area',
      section: CampusSection.west,
      latitude: 14.3260, longitude: 120.9592, icon: Icons.church,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070740605.jpg',
    ),
    CampusLocation(
      id: 'food_square',
      name: 'University Food Square',
      description: 'Dining Area',
      section: CampusSection.west,
      latitude: 14.3215, longitude: 120.9601, icon: Icons.fastfood,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764081832591.jpg',
    ),
    CampusLocation(
      id: 'vbh',
      name: 'Vito Belarmino Hall (VBH)',
      description: 'Campus Building',
      section: CampusSection.west,
      latitude: 14.3221, longitude: 120.9592, icon: Icons.business,
      panoramaUrl:'https://hgaffhpmmmifhoigwoqp.supabase.co/storage/v1/object/public/panoramas/panorama_stitched_1764070929424.jpg',
    ),
  ];
}