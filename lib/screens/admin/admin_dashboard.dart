// lib/screens/admin/admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/custom_button.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class UserFeedback {
  final String id;
  final String email;
  final int rating;
  final String additionalFeedback;
  final List<String> positives;
  final String improvements;
  final String appVersion;
  final DateTime submittedAt;

  UserFeedback({
    required this.id,
    required this.email,
    required this.rating,
    required this.additionalFeedback,
    required this.positives,
    required this.improvements,
    required this.appVersion,
    required this.submittedAt,
  });

  factory UserFeedback.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserFeedback(
      id: doc.id,
      email: data['email'] ?? '',
      rating: data['rating'] ?? 0,
      additionalFeedback: data['additionalFeedback'] ?? '',
      positives: List<String>.from(data['positives'] ?? []),
      improvements: data['improvements'] ?? '',
      appVersion: data['appVersion'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
    );
  }
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // 0: Dashboard, 1-8: Pages, 9: Feedbacks

  final List<AdminPage> _pages = [
    AdminPage(
      title: 'Admissions',
      description: 'Your first step to becoming a Lasallian',
      icon: Icons.school,
      color: AppColors.primaryGreen,
    ),
    AdminPage(
      title: 'Applications',
      description: 'Learn how to apply to DLSU-D',
      icon: Icons.description,
      color: AppColors.accentBlue,
    ),
    AdminPage(
      title: 'Scholarships',
      description: 'Explore merit-based and need-based scholarships',
      icon: Icons.star,
      color: AppColors.warningOrange,
    ),
    AdminPage(
      title: 'Enrollment',
      description: 'The step-by-step process of enrollment',
      icon: Icons.how_to_reg,
      color: AppColors.primaryGreen,
    ),
    AdminPage(
      title: 'Academic Programs',
      description: 'Get to know the diverse academic programs',
      icon: Icons.auto_stories,
      color: AppColors.accentBlue,
    ),
    AdminPage(
      title: 'Research & Innovation',
      description: 'DLSU-D fosters a strong research culture',
      icon: Icons.science,
      color: AppColors.warningOrange,
    ),
    AdminPage(
      title: 'Campus Life',
      description: 'From student organizations to sports',
      icon: Icons.groups,
      color: AppColors.primaryGreen,
    ),
    AdminPage(
      title: 'Global Engagement',
      description: 'Learn about international programs',
      icon: Icons.public,
      color: AppColors.accentBlue,
    ),
  ];

  Stream<List<UserFeedback>> _getFeedbackStream() {
    return FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserFeedback.fromFirestore(doc))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 0) return 'Admin Dashboard';
    if (_selectedIndex >= 1 && _selectedIndex <= 8) {
      return _pages[_selectedIndex - 1].title;
    }
    return 'User Feedbacks';
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'PAGES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ..._pages.asMap().entries.map((entry) {
            int idx = entry.key;
            AdminPage page = entry.value;
            return ListTile(
              leading: Icon(page.icon, color: page.color),
              title: Text(page.title),
              selected: _selectedIndex == idx + 1,
              onTap: () {
                setState(() => _selectedIndex = idx + 1);
                Navigator.pop(context);
              },
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedbacks'),
            selected: _selectedIndex == 9,
            onTap: () {
              setState(() => _selectedIndex = 9);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildDashboardView();
    } else if (_selectedIndex >= 1 && _selectedIndex <= 8) {
      return _buildPageEditorView(_pages[_selectedIndex - 1]);
    } else {
      return _buildFeedbacksView();
    }
  }

  Widget _buildDashboardView() {
    return StreamBuilder<List<UserFeedback>>(
      stream: _getFeedbackStream(),
      builder: (context, snapshot) {
        int feedbackCount = 0;
        if (snapshot.hasData) {
          feedbackCount = snapshot.data!.length;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pages,
                              size: 48,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_pages.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Total Pages',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.feedback,
                              size: 48,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$feedbackCount',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'User Feedbacks',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = index + 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(page.icon, size: 36.0, color: page.color),
                            const SizedBox(height: 8.0),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageEditorView(AdminPage page) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: page.color),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Edit Content',
            onPressed: () {
              // TODO: Navigate to page editor
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbacksView() {
    return StreamBuilder<List<UserFeedback>>(
      stream: _getFeedbackStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No feedback yet.'));
        }

        final feedbacks = snapshot.data!;

        return ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListTile(
                title: Text('Rating: ${feedback.rating} stars'),
                subtitle: Text(feedback.additionalFeedback),
                trailing: Text(feedback.email),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  AdminPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}