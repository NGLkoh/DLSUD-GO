import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dlsud_go/core/theme/app_theme.dart';

// ✅ Import your provider (ensure this path is correct)
import '../../providers/settings_provider.dart'; 
// ✅ Import your other screens
import '../auth/admin_login_screen.dart';
import '../feedback/feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the settings provider
    final settings = Provider.of<SettingsService>(context);
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()), // "Settings"
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          // --- SECTION 1: GENERAL ---
          _buildSettingsSection(
            context,
            'settings.general'.tr(),
            [
               _buildSettingsTile(
                context,
                'settings.app_info'.tr(),
                'Version 1.0.3',
                Icons.info_outline,
                onTap: () => _showAppInfoDialog(context),
              ),
            ]
          ),

          const SizedBox(height: 24),

          // --- SECTION 2: ACCESSIBILITY (Direct Access) ---
          _buildSectionHeader(context, 'settings.accessibility'.tr()),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // 1. High Contrast Switch
                SwitchListTile(
                  secondary: Icon(Icons.contrast, color: appColors.primaryGreen),
                  title: const Text("High Contrast"),
                  value: settings.isHighContrast,
                  activeColor: appColors.primaryGreen,
                  onChanged: (bool value) {
                    settings.updateHighContrast(value);
                  },
                ),
                const Divider(height: 1),
                
                // 2. Text Size Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Text Size", style: TextStyle(fontSize: 16)),
                          Text(
                            "${(settings.textScale * 100).toInt()}%",
                            style: TextStyle(fontWeight: FontWeight.bold, color: appColors.primaryGreen),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.textScale,
                        min: 0.8,
                        max: 1.5,
                        divisions: 7,
                        activeColor: appColors.primaryGreen,
                        onChanged: (val) => settings.updateTextScale(val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- SECTION 3: THEME ---
          _buildSettingsSection(
            context,
            'settings.theme'.tr(),
            [
              _buildSettingsTile(
                context,
                'settings.theme'.tr(),
                settings.themeMode.toString().split('.').last, // "light", "dark", or "system"
                Icons.palette,
                onTap: () => _showThemeDialog(context, settings),
              ),
            ]
          ),

          const SizedBox(height: 24),

          // --- SECTION 4: LANGUAGE ---
          _buildSettingsSection(
            context,
            'settings.language'.tr(),
            [
              const LanguageSettingsTile(), // Your custom widget
            ]
          ),

          const SizedBox(height: 24),

          // --- SECTION 5: SUPPORT ---
          _buildSettingsSection(
            context,
            'settings.support'.tr(),
            [
              _buildSettingsTile(
                context,
                'settings.feedback'.tr(),
                'Report issues',
                Icons.feedback,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                },
              ),
            ]
          ),

          const SizedBox(height: 24),

          // --- SECTION 6: ADMIN ---
          _buildSettingsSection(
            context,
            'settings.admin'.tr(),
            [
              _buildSettingsTile(
                context,
                'settings.admin_login'.tr(),
                'Admin Access',
                Icons.admin_panel_settings,
                color: appColors.primaryGreen,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
                },
              ),
            ]
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: appColors.textMedium,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onTap,
    Color? color,
  }) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return ListTile(
      leading: Icon(icon, color: color ?? appColors.primaryGreen),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: appColors.textMedium)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // --- DIALOGS ---

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.app_info'.tr()),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DLSU-D Go! Version 1.0.3'),
            SizedBox(height: 8),
            Text('A smart campus navigation app with AI-powered assistance.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'.tr())),
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
}

class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return ListTile(
      leading: Icon(Icons.language, color: appColors.primaryGreen),
      title: Text('settings.language'.tr()),
      subtitle: Text(context.locale.languageCode == 'en' ? 'English' : 'Tagalog'),
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
              onChanged: (val) {
                if (val != null) {
                  context.setLocale(val);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<Locale>(
              title: const Text('Tagalog'),
              value: const Locale('tl', 'PH'),
              groupValue: context.locale,
              onChanged: (val) {
                if (val != null) {
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