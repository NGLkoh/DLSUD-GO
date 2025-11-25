import 'package:dlsud_go/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../auth/admin_login_screen.dart';
import '../feedback/feedback_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dlsud_go/core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        // Translated App Bar Title
        title: Text('settings.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            'settings.general'.tr(), // Translated
            [
              _buildSettingsTile(
                context,
                'settings.app_info'.tr(), // Translated
                'Version, developer info',
                Icons.info_outline,
                    () => _showAppInfoDialog(context),
              ),
              _buildSettingsTile(
                context,
                'settings.accessibility'.tr(), // Translated
                'Text size, contrast',
                Icons.accessibility,
                    () => _showAccessibilityDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            'settings.theme'.tr(), // Translated
            [
              _buildSettingsTile(
                context,
                'settings.theme'.tr(), // Translated
                settings.themeMode.toString().split('.').last,
                Icons.palette,
                    () => _showThemeDialog(context, settings),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // --- LANGUAGE SECTION ---
          _buildSettingsSection(
            context,
            'settings.language'.tr(), // Translated
            [
              // 2. REPLACED old _buildSettingsTile with the custom LanguageSettingsTile
              const LanguageSettingsTile(),
            ],
          ),
          // --- END LANGUAGE SECTION ---
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            'settings.support'.tr(), // Translated
            [
              _buildSettingsTile(
                context,
                'settings.feedback'.tr(), // Translated
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
          _buildSettingsSection(
            context,
            'settings.admin'.tr(), // Translated
            [
              _buildSettingsTile(
                context,
                'settings.admin_login'.tr(), // Translated
                'Access administrative features',
                Icons.admin_panel_settings,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                  );
                },
                color: appColors.primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Utility methods remain unchanged ---

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            // Use provided title (which is now translated via .tr() above)
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appColors.textMedium,
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
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        Color? color,
      }) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? appColors.primaryGreen,
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
          color: appColors.textMedium,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // --- Dialogs (Translate titles/content here) ---

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.app_info'.tr()),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DLSU-D Go! Version 1.0.0'),
            SizedBox(height: 8),
            Text('A smart campus navigation app with AI-powered assistance.'),
            SizedBox(height: 16),
            Text('Developed for De La Salle University-Dasmariñas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.accessibility'.tr()),
        content: Text('High contrast and text size settings coming soon!'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.theme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Light'.tr()),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.updateTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark'.tr()),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.updateTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text('System'.tr()),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) {
                settings.updateTheme(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

// 3. REMOVE the old _showLanguageDialog as it's no longer needed.
// The logic is now in the LanguageSettingsTile widget.
}

// 3. ADD THE NEW WIDGET HERE
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    // We recreate the structure of a settings tile, but rely on easy_localization
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text('settings.language'.tr()),
      subtitle: Text(
        // Display the currently selected language
        context.locale.languageCode == 'en' ? 'English' : 'Tagalog',
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: const Text('English'),
              value: const Locale('en', 'US'),
              groupValue: context.locale,
              onChanged: (Locale? val) {
                if (val != null) {
                  // This one line updates the app and persists the locale
                  context.setLocale(val);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<Locale>(
              title: const Text('Tagalog'),
              value: const Locale('tl', 'PH'),
              groupValue: context.locale,
              onChanged: (Locale? val) {
                if (val != null) {
                  // This one line updates the app and persists the locale
                  context.setLocale(val);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
