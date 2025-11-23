// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../dashboard/main_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome header
          _buildWelcomeHeader(),
          
          // Pages list
          Expanded(
            child: _buildPagesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPageDialog(),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hi Admin!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back to your panel.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: page.color.withOpacity(0.05),
                border: Border.all(
                  color: page.color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: page.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      page.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  PopupMenuButton<String>(
                    onSelected: (value) => _handlePageAction(value, index),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.errorRed),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.errorRed)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.more_vert, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePageAction(String action, int index) {
    switch (action) {
      case 'edit':
        _showEditPageDialog(_pages[index], index);
        break;
      case 'delete':
        _showDeleteConfirmDialog(index);
        break;
    }
  }

  void _showEditPageDialog(AdminPage page, int index) {
    final titleController = TextEditingController(text: page.title);
    final descriptionController = TextEditingController(text: page.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Page Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Save',
            onPressed: () {
              setState(() {
                _pages[index] = _pages[index].copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                );
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Page updated successfully');
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Are you sure you want to delete "${_pages[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            color: AppColors.errorRed,
            onPressed: () {
              setState(() {
                _pages.removeAt(index);
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Page deleted successfully');
            },
          ),
        ],
      ),
    );
  }

  void _showAddPageDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    IconData selectedIcon = Icons.info;
    Color selectedColor = AppColors.primaryGreen;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Page Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Icon: '),
                  IconButton(
                    icon: Icon(selectedIcon, color: selectedColor),
                    onPressed: () {
                      // Simple icon selection
                      final icons = [
                        Icons.info,
                        Icons.school,
                        Icons.book,
                        Icons.star,
                        Icons.group,
                        Icons.public,
                      ];
                      setDialogState(() {
                        selectedIcon = icons[(icons.indexOf(selectedIcon) + 1) % icons.length];
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Add',
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _pages.add(AdminPage(
                      title: titleController.text,
                      description: descriptionController.text,
                      icon: selectedIcon,
                      color: selectedColor,
                    ));
                  });
                  Navigator.pop(context);
                  _showSuccessSnackBar('Page added successfully');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Logout',
            color: AppColors.errorRed,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainDashboard()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Data model for admin pages
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

  AdminPage copyWith({
    String? title,
    String? description,
    IconData? icon,
    Color? color,
  }) {
    return AdminPage(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}