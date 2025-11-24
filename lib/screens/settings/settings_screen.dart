// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../auth/admin_login_screen.dart';
import '../feedback/feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  bool _highContrastMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General App Information
          _buildSettingsSection(
            'General',
            [
              _buildSettingsTile(
                'General App Information',
                'App version, developer info',
                Icons.info_outline,
                () => _showAppInfoDialog(context),
              ),
              _buildSettingsTile(
                'Accessibility',
                'Text size, contrast, voice settings',
                Icons.accessibility,
                () => _showAccessibilityDialog(context),
              ),
              _buildSettingsTile(
                'App Permissions',
                'Location, notifications',
                Icons.security,
                () => _showPermissionsDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Display Settings
          _buildSettingsSection(
            'Display',
            [
              _buildSettingsTile(
                'Appearance',
                'Theme',
                Icons.palette,
                () => _showAppearanceDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Language & Preferences
          _buildSettingsSection(
            'Preferences',
            [
              _buildSettingsTile(
                'Language',
                _selectedLanguage,
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildSettingsTile(
                'Privacy & Security',
                'Data usage, location settings',
                Icons.privacy_tip,
                () => _showPrivacyDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Feedback & Support
          _buildSettingsSection(
            'Support',
            [
              _buildSettingsTile(
                'Feedback',
                'Send suggestions or report issues',
                Icons.feedback,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Admin Section
          _buildSettingsSection(
            'Administration',
            [
              _buildSettingsTile(
                'Admin Login',
                'Access administrative features',
                Icons.admin_panel_settings,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                  );
                },
                color: AppColors.primaryGreen,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // App version footer
          _buildAppVersionFooter(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.primaryGreen,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textMedium,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textMedium,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildAppVersionFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'DLSU-D Go!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Developed for De La Salle University-Dasmariñas',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DLSU-D Go! v1.0.0'),
            SizedBox(height: 8),
            Text('A smart campus navigation app with AI-powered assistance.'),
            SizedBox(height: 16),
            Text('Developed for:\nDe La Salle University-Dasmariñas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              value: _highContrastMode,
              onChanged: (value) {
                setState(() {
                  _highContrastMode = value;
                });
                Navigator.pop(context);
              },
            ),
            const ListTile(
              title: Text('Large Text'),
              subtitle: Text('Use system font size settings'),
              trailing: Icon(Icons.font_download),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Permissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Location Services'),
              subtitle: const Text('For navigation and maps'),
              value: _locationServicesEnabled,
              onChanged: (value) {
                setState(() {
                  _locationServicesEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Campus alerts and updates'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('Light Theme'),
              value: false,
              groupValue: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: const Text('Dark Theme'),
              value: true,
              groupValue: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Filipino'),
              value: 'Filipino',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Your privacy is important to us. This app collects minimal data necessary for navigation and functionality. Location data is used only for map services and is not stored permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Learn More'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Start Location: Gate 1'),
            SizedBox(height: 8),
            Text('Preferred Route Type: Walking'),
            SizedBox(height: 8),
            Text('Map Style: Standard'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Customize'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}