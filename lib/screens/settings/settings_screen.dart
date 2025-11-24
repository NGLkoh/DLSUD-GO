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
  double _textSize = 1.0;

  // Language translations
  Map<String, Map<String, String>> _translations = {
    'English': {
      'settings': 'Settings',
      'general': 'General',
      'general_info': 'General App Information',
      'general_info_desc': 'App version, developer info',
      'accessibility': 'Accessibility',
      'accessibility_desc': 'Text size, contrast, voice settings',
      'permissions': 'App Permissions',
      'permissions_desc': 'Location, notifications',
      'display': 'Display',
      'appearance': 'Appearance',
      'appearance_desc': 'Theme',
      'preferences': 'Preferences',
      'language': 'Language',
      'privacy': 'Privacy & Security',
      'privacy_desc': 'Data usage, location settings',
      'support': 'Support',
      'feedback': 'Feedback',
      'feedback_desc': 'Send suggestions or report issues',
      'administration': 'Administration',
      'admin_login': 'Admin Login',
      'admin_login_desc': 'Access administrative features',
      'app_name': 'DLSU-D Go!',
      'version': 'Version 1.0.0',
      'developed_for': 'Developed for De La Salle University-Dasmariñas',
      'close': 'Close',
      'cancel': 'Cancel',
      'save': 'Save',
      'learn_more': 'Learn More',
      'customize': 'Customize',
      'app_info_title': 'App Information',
      'app_info_content': 'A smart campus navigation app with AI-powered assistance.',
      'accessibility_title': 'Accessibility Settings',
      'high_contrast': 'High Contrast Mode',
      'large_text': 'Large Text',
      'large_text_desc': 'Use system font size settings',
      'permissions_title': 'App Permissions',
      'location_services': 'Location Services',
      'location_desc': 'For navigation and maps',
      'notifications': 'Notifications',
      'notifications_desc': 'Campus alerts and updates',
      'appearance_title': 'Appearance',
      'light_theme': 'Light Theme',
      'dark_theme': 'Dark Theme',
      'language_title': 'Select Language',
      'privacy_title': 'Privacy & Security',
      'privacy_content': 'Your privacy is important to us. This app collects minimal data necessary for navigation and functionality. Location data is used only for map services and is not stored permanently.',
      'text_size': 'Text Size',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Large',
    },
    'Filipino': {
      'settings': 'Mga Setting',
      'general': 'Pangkalahatan',
      'general_info': 'Pangkalahatang Impormasyon ng App',
      'general_info_desc': 'Bersyon ng app, impormasyon ng developer',
      'accessibility': 'Accessibility',
      'accessibility_desc': 'Laki ng teksto, contrast, voice settings',
      'permissions': 'Mga Pahintulot ng App',
      'permissions_desc': 'Lokasyon, notipikasyon',
      'display': 'Display',
      'appearance': 'Hitsura',
      'appearance_desc': 'Tema',
      'preferences': 'Mga Kagustuhan',
      'language': 'Wika',
      'privacy': 'Privacy at Seguridad',
      'privacy_desc': 'Paggamit ng data, settings ng lokasyon',
      'support': 'Suporta',
      'feedback': 'Feedback',
      'feedback_desc': 'Magpadala ng mga mungkahi o iulat ang mga isyu',
      'administration': 'Administrasyon',
      'admin_login': 'Admin Login',
      'admin_login_desc': 'I-access ang mga administrative features',
      'app_name': 'DLSU-D Go!',
      'version': 'Bersyon 1.0.0',
      'developed_for': 'Ginawa para sa De La Salle University-Dasmariñas',
      'close': 'Isara',
      'cancel': 'Kanselahin',
      'save': 'I-save',
      'learn_more': 'Matuto Pa',
      'customize': 'I-customize',
      'app_info_title': 'Impormasyon ng App',
      'app_info_content': 'Isang matalinong campus navigation app na may AI-powered na tulong.',
      'accessibility_title': 'Mga Setting ng Accessibility',
      'high_contrast': 'High Contrast Mode',
      'large_text': 'Malaking Teksto',
      'large_text_desc': 'Gamitin ang system font size settings',
      'permissions_title': 'Mga Pahintulot ng App',
      'location_services': 'Mga Serbisyo ng Lokasyon',
      'location_desc': 'Para sa nabigasyon at mga mapa',
      'notifications': 'Mga Notipikasyon',
      'notifications_desc': 'Mga alerto at update sa campus',
      'appearance_title': 'Hitsura',
      'light_theme': 'Light Theme',
      'dark_theme': 'Dark Theme',
      'language_title': 'Pumili ng Wika',
      'privacy_title': 'Privacy at Seguridad',
      'privacy_content': 'Mahalaga sa amin ang iyong privacy. Ang app na ito ay nangongolekta ng minimal na data na kailangan para sa nabigasyon at functionality. Ang data ng lokasyon ay ginagamit lamang para sa mga serbisyo ng mapa at hindi naka-imbak nang permanente.',
      'text_size': 'Laki ng Teksto',
      'small': 'Maliit',
      'medium': 'Katamtaman',
      'large': 'Malaki',
    },
  };

  String _t(String key) {
    return _translations[_selectedLanguage]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(_t('settings')),
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
          // General Section
          _buildSettingsSection(
            _t('general'),
            [
              _buildSettingsTile(
                _t('general_info'),
                _t('general_info_desc'),
                Icons.info_outline,
                    () => _showAppInfoDialog(context),
              ),
              _buildSettingsTile(
                _t('accessibility'),
                _t('accessibility_desc'),
                Icons.accessibility,
                    () => _showAccessibilityDialog(context),
              ),
              _buildSettingsTile(
                _t('permissions'),
                _t('permissions_desc'),
                Icons.security,
                    () => _showPermissionsDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Display Settings
          _buildSettingsSection(
            _t('display'),
            [
              _buildSettingsTile(
                _t('appearance'),
                _darkModeEnabled ? _t('dark_theme') : _t('light_theme'),
                Icons.palette,
                    () => _showAppearanceDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Language & Preferences
          _buildSettingsSection(
            _t('preferences'),
            [
              _buildSettingsTile(
                _t('language'),
                _selectedLanguage,
                Icons.language,
                    () => _showLanguageDialog(context),
              ),
              _buildSettingsTile(
                _t('privacy'),
                _t('privacy_desc'),
                Icons.privacy_tip,
                    () => _showPrivacyDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Feedback & Support
          _buildSettingsSection(
            _t('support'),
            [
              _buildSettingsTile(
                _t('feedback'),
                _t('feedback_desc'),
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
            _t('administration'),
            [
              _buildSettingsTile(
                _t('admin_login'),
                _t('admin_login_desc'),
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

  Widget _buildAppVersionFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            _t('app_name'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t('version'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('developed_for'),
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
        title: Text(_t('app_info_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_t('app_name')} ${_t('version')}'),
            const SizedBox(height: 8),
            Text(_t('app_info_content')),
            const SizedBox(height: 16),
            Text('${_t('developed_for')}\nDe La Salle University-Dasmariñas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('close')),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t('accessibility_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(_t('high_contrast')),
                value: _highContrastMode,
                onChanged: (value) {
                  setState(() {
                    _highContrastMode = value;
                  });
                  setDialogState(() {
                    _highContrastMode = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
              const Divider(),
              ListTile(
                title: Text(_t('text_size')),
                subtitle: Slider(
                  value: _textSize,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: _textSize == 0.8
                      ? _t('small')
                      : _textSize == 1.0
                      ? _t('medium')
                      : _t('large'),
                  activeColor: AppColors.primaryGreen,
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                    setDialogState(() {
                      _textSize = value;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('close')),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t('permissions_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(_t('location_services')),
                subtitle: Text(_t('location_desc')),
                value: _locationServicesEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationServicesEnabled = value;
                  });
                  setDialogState(() {
                    _locationServicesEnabled = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
              SwitchListTile(
                title: Text(_t('notifications')),
                subtitle: Text(_t('notifications_desc')),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  setDialogState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('close')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t('appearance_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: Text(_t('light_theme')),
                value: false,
                groupValue: _darkModeEnabled,
                activeColor: AppColors.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value!;
                  });
                  setDialogState(() {});
                  Navigator.pop(context);
                  // Show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_t('light_theme')} ${_t('save').toLowerCase()}d'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              RadioListTile<bool>(
                title: Text(_t('dark_theme')),
                value: true,
                groupValue: _darkModeEnabled,
                activeColor: AppColors.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value!;
                  });
                  setDialogState(() {});
                  Navigator.pop(context);
                  // Show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_t('dark_theme')} ${_t('save').toLowerCase()}d'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t('language_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                activeColor: AppColors.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  // Show confirmation snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language changed to English'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              RadioListTile<String>(
                title: const Text('Filipino'),
                value: 'Filipino',
                groupValue: _selectedLanguage,
                activeColor: AppColors.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  // Show confirmation snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pinalitan ang wika sa Filipino'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('privacy_title')),
        content: Text(_t('privacy_content')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would open a detailed privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('learn_more')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(_t('learn_more')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('close')),
          ),
        ],
      ),
    );
  }
}