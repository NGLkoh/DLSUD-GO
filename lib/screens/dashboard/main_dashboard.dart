import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dlsud_go/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/dashboard_section.dart';
import '../../widgets/common/custom_button.dart';
import '../chatbot/chatbot_screen.dart';
import '../map/navigation/map_navigation_screen.dart';
import '../search/search_screen.dart';
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

  List<Widget> get _pages => [
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
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: appColors.backgroundColor,
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
      bottomNavigationBar: _buildBottomNavigationBar(appColors),
    );
  }

  Widget _buildBottomNavigationBar(AppColorsExtension appColors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (appColors.textLight ?? Colors.grey).withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: appColors.primaryGreen,
        unselectedItemColor: appColors.textLight,
        backgroundColor: appColors.cardBackground ?? Theme.of(context).cardColor,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore),
            label: 'dashboard.explore'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: 'dashboard.maps'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: 'dashboard.chatbot'.tr(),
          ),
        ],
      ),
    );
  }
}

class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  // --- HELPER: MAP DB TITLES TO TRANSLATION KEYS ---
  String _getTranslatedTitle(String dbTitle) {
    final key = dbTitle.toLowerCase().trim();
    if (key.contains('admission')) return 'sections.admissions_title'.tr();
    if (key.contains('program')) return 'sections.programs_title'.tr();
    if (key.contains('map')) return 'sections.maps_title'.tr();
    if (key.contains('research')) return 'sections.research_title'.tr();
    if (key.contains('global')) return 'sections.global_title'.tr();
    // Fallback: return the original DB text if no translation found
    return dbTitle;
  }

  String _getTranslatedDescription(String dbTitle, String originalDesc) {
    final key = dbTitle.toLowerCase().trim();
    if (key.contains('admission')) return 'sections.admissions_desc'.tr();
    if (key.contains('program')) return 'sections.programs_desc'.tr();
    if (key.contains('map')) return 'sections.maps_desc'.tr();
    if (key.contains('research')) return 'sections.research_desc'.tr();
    if (key.contains('global')) return 'sections.global_desc'.tr();
    return originalDesc;
  }
  // --------------------------------------------------

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

  Color _getColorFromHex(BuildContext context, String hexColor) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return appColors.primaryGreen ?? const Color(0xFF2D6A4F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final primaryGreen = appColors.primaryGreen ?? const Color(0xFF2D6A4F);
    final lightGreen = appColors.lightGreen ?? const Color(0xFF52B788);

    return Scaffold(
      backgroundColor: appColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: appColors.backgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGreen,
                      lightGreen,
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
                        Text(
                          'dashboard.welcome'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'dashboard.patriot'.tr(),
                          style: const TextStyle(
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                StreamBuilder<List<DashboardSection>>(
                  stream: _getSectionsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: appColors.primaryGreen,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'dashboard.error'.tr(args: [snapshot.error.toString()]),
                          style: TextStyle(color: appColors.textDark),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'dashboard.no_sections'.tr(),
                          style: TextStyle(color: appColors.textDark),
                        ),
                      );
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
                      return Center(
                        child: CircularProgressIndicator(
                          color: appColors.primaryGreen,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox();
                    }
                    return _buildCampusInfoSection(context, snapshot.data!);
                  },
                ),
                const SizedBox(height: 32),
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
        // USE HELPERS TO GET TRANSLATED TEXT
        final displayTitle = _getTranslatedTitle(section.title);
        final displayDesc = _getTranslatedDescription(section.title, section.description);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildServiceCard(
            context,
            displayTitle, // Use translated title
            displayDesc,  // Use translated description
            _getIconFromString(section.iconName),
            _getColorFromHex(context, section.colorHex),
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
                      title: displayTitle, // Pass translated title
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

    final truncatedSubtitle = subtitle.length > 80
        ? '${subtitle.substring(0, 80)}...'
        : subtitle;

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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      truncatedSubtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard.quick_access'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: appColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'dashboard.chat_assistant'.tr(),
                Icons.chat,
                appColors.primaryGreen ?? const Color(0xFF2D6A4F),
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
                context,
                'settings.title'.tr(),
                Icons.settings,
                appColors.textMedium ?? Colors.grey,
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
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: appColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED CAMPUS INFO SECTION
  Widget _buildCampusInfoSection(BuildContext context, Map<String, dynamic> data) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    // 1. Translate Title and Button using keys
    final title = 'campus_info.title'.tr();
    final buttonText = 'campus_info.button'.tr();

    // 2. Translate Subtitle
    // We use the key directly for the subtitle to ensure it translates
    final subtitle = 'campus_info.subtitle'.tr();

    // 3. Handle Description Translation (The long text)
    // We grab the raw text from the database
    String rawDescription = data['description'] ?? '';
    String description = rawDescription;

    // LOGIC: If the text from DB looks like the "About" description (starts with "De La Salle"),
    // we force it to use our translated key instead of the raw English text.
    if (rawDescription.trim().startsWith("De La Salle")) {
      description = 'campus_info.about_description'.tr();
    }

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
                    color: appColors.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: appColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Display the description (which is now translated if it matched)
            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: appColors.textMedium,
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
  }
}