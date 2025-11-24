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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with hero image and title
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image placeholder - replace with actual campus image
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
                  // Hero section with DLSU statue/campus image
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'De La Salle University-Dasmariñas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
                unselectedLabelColor: AppColors.textMedium,
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
      // Chat button for questions
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

    if (descriptions.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('No content available for this section.'),
      ));
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

          // Help section
          _buildHelpSection(),
        ],
      ),
    );
  }

  Widget _getStaticSectionContent(String section) {
    switch (section) {
      case 'Student Services & Administration':
        return _buildStudentServicesContent();
      case 'Admissions':
        return _buildAdmissionsContent();
      case 'Payment':
        return _buildPaymentContent();
      case 'Office Location':
        return _buildOfficeLocationContent();
      case 'Academic Calendar':
        return _buildAcademicCalendarContent();
      case 'Health & Security':
        return _buildHealthSecurityContent();
      case 'Educational Tours':
        return _buildEducationalToursContent();
      case 'Off-campus Activities':
        return _buildOffCampusActivitiesContent();
      case 'Exchange Student Programs':
        return _buildExchangeProgramsContent();
      case 'General Admissions Policy':
        return _buildGeneralAdmissionsPolicyContent();
      case 'Campus Life':
        return _buildCampusLifeContent();
      case 'Academic Programs':
        return _buildAcademicProgramsContent();
      case 'Global Engagement':
        return _buildGlobalEngagementContent();
      default:
        return _buildDefaultContent(section);
    }
  }

  Widget _buildStudentServicesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Student Services',
          'Comprehensive support services for all students',
          Icons.support_agent,
          [
            'Academic advising and counseling',
            'Student records and transcripts',
            'Scholarship and financial aid assistance',
            'Career guidance and placement services',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Office Hours',
          'Monday to Friday: 8:00 AM - 4:00 PM',
          Icons.access_time,
          [
            'Walk-in consultations welcome',
            'Online appointments available',
            'Emergency support during weekends',
          ],
        ),
      ],
    );
  }

  Widget _buildAdmissionsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'General Admissions Policy',
          'DLSU-D implements open admission policy',
          Icons.policy,
          [
            'All senior high school graduates eligible',
            'Old basic education curriculum graduates accepted',
            'Undergraduate programs and experienced Lasallian education available',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Requirements',
          'Documents needed for admission',
          Icons.description,
          [
            'High school diploma or equivalent',
            'Official transcripts of records',
            'Birth certificate (NSO copy)',
            'Medical certificate',
            'Passport-size photos (2x2)',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Application Process',
          'Simple steps to join DLSU-D',
          Icons.how_to_reg,
          [
            '1. Submit application form online',
            '2. Upload required documents',
            '3. Pay application fee',
            '4. Wait for admission confirmation',
            '5. Complete enrollment process',
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Cashier Office',
          'Located at ground floor of Ayuntamiento de Gonzales Hall',
          Icons.account_balance,
          [
            'Tuition and miscellaneous fees payment',
            'Installment plans available',
            'Cash, check, and online payments accepted',
            'Official receipts provided for all transactions',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Payment Schedule',
          'Flexible payment options',
          Icons.schedule,
          [
            'Full payment: 10% discount on tuition',
            'Two installments: 50% before enrollment, 50% midterm',
            'Three installments: Available for certain programs',
            'Monthly payment plans with zero interest',
          ],
        ),
      ],
    );
  }

  Widget _buildOfficeLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Main Administration Building',
          'Ayuntamiento de Gonzales Hall',
          Icons.business,
          [
            'Ground Floor: Cashier, Registrar, Admissions',
            'Second Floor: Student Affairs, Guidance Office',
            'Third Floor: Academic Affairs, Dean\'s Offices',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Student Services Centers',
          'Multiple locations across campus',
          Icons.room,
          [
            'Library: Research and study assistance',
            'IT Center: Technical support and computer labs',
            'Health Services: Medical clinic and first aid',
            'Sports Complex: Athletic facilities and programs',
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicCalendarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          '2025 Academic Year',
          'Important dates and schedules',
          Icons.calendar_today,
          [
            'First Semester: August - December 2025',
            'Second Semester: January - May 2026',
            'Summer Classes: June - July 2026',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Key Dates',
          'Mark your calendar',
          Icons.event,
          [
            'Enrollment Period: March - August 2025',
            'Classes Begin: August 12, 2025',
            'Midterm Break: October 14-18, 2025',
            'Final Examinations: December 2-13, 2025',
            'Christmas Break: December 16, 2025 - January 6, 2026',
          ],
        ),
      ],
    );
  }

  Widget _buildHealthSecurityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Health Services',
          '24/7 medical support on campus',
          Icons.local_hospital,
          [
            'On-campus medical clinic',
            'Registered nurses on duty',
            'Emergency response team',
            'Health insurance partnerships',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Security Services',
          'Safe and secure campus environment',
          Icons.security,
          [
            'Campus security patrol',
            'CCTV monitoring system',
            'Emergency hotlines',
            'Visitor registration system',
            'Well-lit pathways and buildings',
          ],
        ),
      ],
    );
  }

  Widget _buildEducationalToursContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Local Educational Tours',
          'Explore Philippine culture and history',
          Icons.tour,
          [
            'Historical sites in Cavite and Manila',
            'Museums and cultural centers',
            'Industrial plant visits',
            'Government institutions tours',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'International Study Tours',
          'Global learning experiences',
          Icons.flight,
          [
            'Exchange programs with partner universities',
            'Cultural immersion programs',
            'Language learning tours',
            'International conferences and seminars',
          ],
        ),
      ],
    );
  }

  Widget _buildOffCampusActivitiesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Community Service',
          'Serving the local community',
          Icons.volunteer_activism,
          [
            'Outreach programs in local barangays',
            'Environmental conservation projects',
            'Feeding programs for underprivileged',
            'Educational assistance for out-of-school youth',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Cultural Activities',
          'Celebrating arts and culture',
          Icons.celebration,
          [
            'Inter-school competitions',
            'Cultural festivals participation',
            'Art exhibitions and performances',
            'Sports tournaments and leagues',
          ],
        ),
      ],
    );
  }

  Widget _buildExchangeProgramsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'International Exchange',
          'Study abroad opportunities',
          Icons.public,
          [
            'Semester exchange with partner universities',
            'Summer programs in Asia and Europe',
            'Language immersion courses',
            'Research collaboration projects',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Partner Universities',
          'Global Lasallian network',
          Icons.school,
          [
            'De La Salle University Manila',
            'La Salle University Philadelphia',
            'Christian Brothers University Memphis',
            'Universities in 79 countries worldwide',
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralAdmissionsPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DLSU-D implements an open admission policy allowing all senior high school graduates and high school graduates of the old basic education curriculum to take any of the undergraduate programs and experience Lasallian education.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          'Admission Requirements',
          'Based on applicant\'s qualifications',
          Icons.checklist,
          [
            'Academic records evaluation',
            'Entrance examination (if required)',
            'Interview with admissions committee',
            'Portfolio review (for specific programs)',
          ],
        ),
      ],
    );
  }

  Widget _buildCampusLifeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Student Organizations',
          'Join and lead campus communities',
          Icons.groups,
          [
            'Academic and professional organizations',
            'Cultural and arts groups',
            'Sports clubs and teams',
            'Service and volunteer organizations',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Campus Facilities',
          'Modern facilities for learning and recreation',
          Icons.domain,
          [
            'State-of-the-art laboratories',
            'Comprehensive library resources',
            'Sports and recreation centers',
            'Student lounges and study areas',
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicProgramsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Undergraduate Programs',
          'Diverse academic offerings',
          Icons.auto_stories,
          [
            'Business and Economics',
            'Engineering and Technology',
            'Liberal Arts and Communication',
            'Education and Human Development',
            'Science and Mathematics',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Graduate Programs',
          'Advanced degrees for career advancement',
          Icons.school,
          [
            'Master\'s degree programs',
            'Doctoral programs',
            'Professional development courses',
            'Research opportunities',
          ],
        ),
      ],
    );
  }

  Widget _buildGlobalEngagementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'International Programs',
          'Global learning opportunities',
          Icons.language,
          [
            'Student exchange programs',
            'International internships',
            'Study abroad semesters',
            'Global research collaborations',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Lasallian Network',
          'Part of a global educational community',
          Icons.connect_without_contact,
          [
            'Connected to 79+ countries',
            'Shared educational values',
            'International faculty exchange',
            'Global alumni network',
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultContent(String section) {
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
        const Text(
          'Welcome to this section of DLSU-D information. Here you\'ll find comprehensive details about our programs, services, and opportunities.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textMedium,
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
    return Card(
      margin: EdgeInsets.zero,
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
                    color: AppColors.primaryGreen.withOpacity(0.1),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
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
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 12),
                Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Can\'t find what you\'re looking for? Our AI assistant is here to help answer your questions about DLSU-D.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
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

  _SliverTabBarDelegate(this._tabBar);

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
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
