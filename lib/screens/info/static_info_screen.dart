// lib/screens/info/static_info_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../chatbot/chatbot_screen.dart';

class StaticInfoScreen extends StatefulWidget {
  final String title;
  final List<dynamic> sections;

  const StaticInfoScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  @override
  State<StaticInfoScreen> createState() => _StaticInfoScreenState();
}

class _StaticInfoScreenState extends State<StaticInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.sections.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            centerTitle: true,
            backgroundColor: AppColors.primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
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
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'De La Salle University-Dasmariñas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: widget.sections.length > 3,
                indicatorColor: AppColors.primaryGreen,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: isDark ? Colors.grey[500] : AppColors.textMedium,
                tabs: widget.sections.map((section) {
                  final title = section is String
                      ? section
                      : (section as Map<String, dynamic>)['title'] as String? ?? '';

                  return Tab(
                    child: Center(
                      child: Text(title, textAlign: TextAlign.center),
                    ),
                  );
                }).toList(),
              ),
              isDark,
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: widget.sections.map((section) {
                if (section is String) {
                  return _buildStaticSectionContent(section);
                } else {
                  return _buildDynamicSectionContent(
                      section as Map<String, dynamic>);
                }
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          'Ask Questions',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDynamicSectionContent(Map<String, dynamic> section) {
    final title = section['title'] as String? ?? '';
    final descriptions = List<String>.from(
      section['details'] ??
          section['descriptions'] ??
          [],
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (descriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No content available for this section.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : AppColors.textMedium,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(title, '', Icons.description, descriptions),
          const SizedBox(height: 40),
          _buildHelpSection(),
        ],
      ),
    );
  }

  Widget _buildStaticSectionContent(String section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getStaticSectionContent(section),
          const SizedBox(height: 40),
          _buildHelpSection(),
        ],
      ),
    );
  }

  Widget _getStaticSectionContent(String section) {
    switch (section) {
      case 'Student Services & Administration':
      default:
        return _buildDefaultContent(section);
    }
  }

  Widget _buildDefaultContent(String section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to this section of DLSU-D information. Here you\'ll find comprehensive details about our programs, services, and opportunities.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: isDark ? Colors.grey[400] : AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          'More Information',
          'Contact us for detailed information',
          Icons.info,
          [
            'Visit the admissions office',
            'Call our hotline: (046) 481-1900',
            'Email: info@dlsud.edu.ph',
            'Check our official website',
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String title,
      String subtitle,
      IconData icon,
      List<String> items,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryGreen.withOpacity(0.15)
                        : AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : AppColors.textMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Can\'t find what you\'re looking for? Our AI assistant is here to help answer your questions about DLSU-D.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textMedium,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Assistant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom delegate for tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this._tabBar, this.isDark);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return isDark != oldDelegate.isDark;
  }
}