import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dlsud_go/screens/dashboard/main_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_section.dart';
import 'section_editor_screen.dart';
import 'campus_info_editor_screen.dart';

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
  final String platform;
  final String appVersion;
  final DateTime submittedAt;

  UserFeedback({
    required this.id,
    required this.email,
    required this.rating,
    required this.additionalFeedback,
    required this.positives,
    required this.platform,
    required this.appVersion,
    required this.submittedAt,
  });

  factory UserFeedback.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    String platform = '';
    if (data['improvements'] != null) {
      if (data['improvements'] is Map<String, dynamic>) {
        platform = (data['improvements'] as Map<String, dynamic>)['platform'] ?? '';
      } else if (data['improvements'] is String) {
        platform = data['improvements'] as String;
      }
    }

    return UserFeedback(
      id: doc.id,
      email: data['email'] ?? '',
      rating: data['rating'] ?? 0,
      additionalFeedback: data['additional_feedback'] ?? '',
      positives: List<String>.from(data['positives'] ?? []),
      platform: platform,
      appVersion: data['app_version'] ?? '',
      submittedAt: (data['submitted_at'] as Timestamp).toDate(),
    );
  }
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // 0: Dashboard, 1: Sections, 2: Campus Info, 3: Feedbacks

  Stream<List<UserFeedback>> _getFeedbackStream() {
    return FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('submitted_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserFeedback.fromFirestore(doc))
        .toList());
  }

  Stream<List<DashboardSection>> _getSectionsStream() {
    return FirebaseFirestore.instance
        .collection('dashboard_sections')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DashboardSection.fromFirestore(doc))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainDashboard()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 1 ? _buildAddSectionFAB() : null,
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Dashboard Sections';
      case 2:
        return 'Campus Info';
      case 3:
        return 'User Feedbacks';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _buildDrawer() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: appColors.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: appColors.textDark,
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: appColors.textDark,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'CONTENT MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: appColors.textMedium,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.view_module, color: appColors.accentBlue),
            title: const Text('Dashboard Sections'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: appColors.warningOrange),
            title: const Text('Campus Info'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('User Feedbacks'),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return _buildSectionsView();
      case 2:
        return _buildCampusInfoView();
      case 3:
        return _buildFeedbacksView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return StreamBuilder<List<UserFeedback>>(
      stream: _getFeedbackStream(),
      builder: (context, feedbackSnapshot) {
        return StreamBuilder<List<DashboardSection>>(
          stream: _getSectionsStream(),
          builder: (context, sectionsSnapshot) {
            int feedbackCount = feedbackSnapshot.data?.length ?? 0;
            int sectionsCount = sectionsSnapshot.data?.length ?? 0;
            int activeSections = sectionsSnapshot.data?.where((s) => s.isActive).length ?? 0;

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
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        'Dashboard Sections',
                        '$sectionsCount',
                        Icons.view_module,
                        appColors.primaryGreen!,
                        'Active: $activeSections',
                      ),
                      _buildStatCard(
                        'User Feedbacks',
                        '$feedbackCount',
                        Icons.feedback,
                        appColors.accentBlue!,
                        'Total received',
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
                  _buildQuickActionCard(
                    'Manage Dashboard Sections',
                    'Add, edit, or reorder sections',
                    Icons.view_module,
                    appColors.primaryGreen!,
                        () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionCard(
                    'Edit Campus Info',
                    'Update campus information card',
                    Icons.info,
                    appColors.warningOrange!,
                        () => setState(() => _selectedIndex = 2),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionCard(
                    'View Feedbacks',
                    'Check user feedback and ratings',
                    Icons.feedback,
                    appColors.accentBlue!,
                        () => setState(() => _selectedIndex = 3),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: appColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionsView() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return StreamBuilder<List<DashboardSection>>(
      stream: _getSectionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_module, size: 64, color: appColors.textMedium),
                const SizedBox(height: 16),
                const Text('No sections yet. Add one to get started!'),
              ],
            ),
          );
        }

        final sections = snapshot.data!;
        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          onReorder: (oldIndex, newIndex) {
            _reorderSections(sections, oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSectionCard(section, key: ValueKey(section.id));
          },
        );
      },
    );
  }

  Widget _buildSectionCard(DashboardSection section, {required Key key}) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: appColors.textMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorFromHex(section.colorHex).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconFromString(section.iconName),
                color: _getColorFromHex(section.colorHex),
              ),
            ),
          ],
        ),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    section.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: section.isActive
                      ? appColors.successGreen!.withOpacity(0.1)
                      : appColors.textLight!.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                if (section.subsections.isNotEmpty)
                  Chip(
                    label: Text(
                      '${section.subsections.length} subsections',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: appColors.accentBlue!.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: appColors.accentBlue),
              onPressed: () => _navigateToEditor(section),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: appColors.errorRed),
              onPressed: () => _confirmDelete(section),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _reorderSections(List<DashboardSection> sections, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final batch = FirebaseFirestore.instance.batch();

    // Update order for all sections
    for (int i = 0; i < sections.length; i++) {
      int newOrder;
      if (i == oldIndex) {
        newOrder = newIndex;
      } else if (oldIndex < newIndex) {
        if (i > oldIndex && i <= newIndex) {
          newOrder = i - 1;
        } else {
          newOrder = i;
        }
      } else {
        if (i >= newIndex && i < oldIndex) {
          newOrder = i + 1;
        } else {
          newOrder = i;
        }
      }

      final docRef = FirebaseFirestore.instance
          .collection('dashboard_sections')
          .doc(sections[i].id);
      batch.update(docRef, {'order': newOrder});
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sections reordered')),
    );
  }

  void _confirmDelete(DashboardSection section) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${section.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSection(section.id);
            },
            style: TextButton.styleFrom(foregroundColor: appColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteSection(String sectionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('dashboard_sections')
          .doc(sectionId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _navigateToEditor(DashboardSection? section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionEditorScreen(section: section),
      ),
    );
  }

  Widget _buildAddSectionFAB() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return FloatingActionButton.extended(
      onPressed: () => _navigateToEditor(null),
      icon: const Icon(Icons.add),
      label: const Text('Add Section'),
      backgroundColor: appColors.primaryGreen,
    );
  }

  Widget _buildCampusInfoView() {
    return CampusInfoEditorScreen();
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'school': Icons.school,
      'map': Icons.map,
      'groups': Icons.groups,
      'info': Icons.info,
      'book': Icons.book,
      'event': Icons.event,
    };
    return iconMap[iconName] ?? Icons.info;
  }

  Color _getColorFromHex(String hexColor) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return appColors.primaryGreen!;
    }
  }

  Widget _buildFeedbacksView() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

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
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < feedback.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        Text(
                          DateFormat.yMMMd().add_jm().format(feedback.submittedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feedback.additionalFeedback,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (feedback.positives.isNotEmpty) ...[
                      const Text(
                        'What went well:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: feedback.positives.map((positive) {
                          return Chip(
                            label: Text(positive),
                            backgroundColor: appColors.primaryGreen!.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feedback.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textMedium,
                          ),
                        ),
                        Text(
                          'v${feedback.appVersion} (${feedback.platform.split('.').last})',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
