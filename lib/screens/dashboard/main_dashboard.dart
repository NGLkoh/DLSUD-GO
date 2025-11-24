// lib/screens/dashboard/main_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dlsud_go/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/dashboard_section.dart';
import '../../widgets/common/custom_button.dart';
import '../chatbot/chatbot_screen.dart';
import '../map/navigation/map_navigation_screen.dart';
import '../settings/settings_screen.dart';
import '../info/static_info_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const DashboardHomeTab(),
    const MapNavigationScreen(),
    const ChatbotScreen(),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
        ],
      ),
    );
  }
}

class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  Stream<List<DashboardSection>> _getSectionsStream() {
    return FirebaseFirestore.instance
        .collection('dashboard_sections')
        .where('is_active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DashboardSection.fromFirestore(doc))
        .toList());
  }

  Stream<Map<String, dynamic>> _getCampusInfoStream() {
    return FirebaseFirestore.instance
        .collection('campus_info')
        .doc('main')
        .snapshots()
        .map((doc) => doc.exists ? doc.data() as Map<String, dynamic> : {});
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'school': Icons.school,
      'map': Icons.map,
      'groups': Icons.groups,
      'info': Icons.info,
      'book': Icons.book,
      'event': Icons.event,
      'sports': Icons.sports,
      'restaurant': Icons.restaurant,
      'local_library': Icons.local_library,
      'science': Icons.science,
      'computer': Icons.computer,
      'language': Icons.language,
    };
    return iconMap[iconName] ?? Icons.info;
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.lightGreen,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Patriot!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapNavigationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                StreamBuilder<List<DashboardSection>>(
                  stream: _getSectionsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No sections available'));
                    }

                    final sections = snapshot.data!;
                    return _buildMainServiceCards(context, sections);
                  },
                ),
                const SizedBox(height: 32),
                _buildQuickAccessSection(context),
                const SizedBox(height: 32),
                StreamBuilder<Map<String, dynamic>>(
                  stream: _getCampusInfoStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox();
                    }
                    return _buildCampusInfoSection(context, snapshot.data!);
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainServiceCards(BuildContext context, List<DashboardSection> sections) {
    return Column(
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildServiceCard(
            context,
            section.title,
            section.description,
            _getIconFromString(section.iconName),
            _getColorFromHex(section.colorHex),
                () {
              if (section.route == 'map_navigation') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapNavigationScreen()),
                );
              } else if (section.route == 'static_info') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaticInfoScreen(
                      title: section.title,
                      sections: section.subsections.map((s) {
                        return {
                          'title': s['title'] ?? '',
                          'details': List<String>.from(
                            s['descriptions'] ?? s['details'] ?? [],
                          ),
                        };
                      }).toList(),
                    ),
                  ),

                  );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                'Chat Assistant',
                Icons.chat,
                AppColors.primaryGreen,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                'Settings',
                Icons.settings,
                AppColors.textMedium,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampusInfoSection(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] ?? 'De La Salle University-Dasmariñas';
    final subtitle = data['subtitle'] ?? 'Your gateway to campus navigation and services';
    final description = data['description'] ?? '';
    final buttonText = data['button_text'] ?? 'Learn More';

    // FIXED: button_sections is now List<Map>
    final buttonSections = List<Map<String, dynamic>>.from(
        data['button_sections'] ?? []
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          )),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          )),
                    ],
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMedium,
                ),
              ),
            ],

            if (buttonSections.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: buttonText,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StaticInfoScreen(
                        title: title,
                        sections: buttonSections.map((section) {
                          return {
                            'title': section['title'] ?? '',
                            'details': List<String>.from(section['details'] ?? []),
                          };
                        }).toList(),
                      ),
                    ),
                  );
                },
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }}
