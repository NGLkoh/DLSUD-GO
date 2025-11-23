// lib/screens/dashboard/main_dashboard.dart
import 'package:dlsud_go/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
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

  // Bottom navigation pages
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

// Home tab content for the dashboard
class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with welcome message and settings
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
                  // Navigate to search functionality
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
          
          // Main content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Main service cards
                _buildMainServiceCards(context),
                
                const SizedBox(height: 32),
                
                // Quick access section
                _buildQuickAccessSection(context),
                
                const SizedBox(height: 32),
                
                // Campus info section
                _buildCampusInfoSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainServiceCards(BuildContext context) {
    return Column(
      children: [
        _buildServiceCard(
          context,
          'Academic Services',
          'Access student services, admissions, and more',
          Icons.school,
          AppColors.primaryGreen,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StaticInfoScreen(
                  title: 'Academic Services',
                  sections: [
                    'Student Services & Administration',
                    'Admissions',
                    'Payment',
                    'Office Location',
                    'Academic Calendar',
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildServiceCard(
          context,
          'Maps',
          'Navigate around campus with interactive maps',
          Icons.map,
          AppColors.accentBlue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapNavigationScreen()),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildServiceCard(
          context,
          'Opportunities & Engagement',
          'Explore student life, activities, and programs',
          Icons.groups,
          AppColors.warningOrange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StaticInfoScreen(
                  title: 'Student Life & Support',
                  sections: [
                    'Health & Security',
                    'Educational Tours',
                    'Off-campus Activities',
                    'Exchange Student Programs',
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
                style: TextStyle(
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

  Widget _buildCampusInfoSection(BuildContext context) {
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
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'De La Salle University-Dasmariñas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your gateway to campus navigation and services',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Welcome to De La Salle University-Dasmariñas, a proud member of the Lasallian network of institutions in 79 countries. Our curriculum is thoughtfully designed to develop the competencies needed for our chosen field and to prepare you to be a leader in your community.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMedium,
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Learn More',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaticInfoScreen(
                      title: 'About DLSU-D',
                      sections: [
                        'General Admissions Policy',
                        'Campus Life',
                        'Academic Programs',
                        'Global Engagement',
                      ],
                    ),
                  ),
                );
              },
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }
}