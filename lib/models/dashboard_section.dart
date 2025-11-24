import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardSection {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String colorHex;
  final String route;
  final List<Map<String, dynamic>> subsections;
  final bool isActive;
  final int order;

  DashboardSection({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.route,
    required this.subsections,
    required this.isActive,
    required this.order,
  });

  factory DashboardSection.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return DashboardSection(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['icon_name'] ?? 'info',
      colorHex: data['color_hex'] ?? '#00563F',
      route: data['route'] ?? 'static_info',
      subsections: (data['subsections'] is List)
          ? data['subsections']
          .where((item) => item is Map<String, dynamic>)
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList()
          : [],
      isActive: data['is_active'] ?? true,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'route': route,
      'subsections': subsections,
      'is_active': isActive,
      'order': order,
    };
  }
}
