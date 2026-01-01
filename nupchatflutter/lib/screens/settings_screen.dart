import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../features/drm/screens/submissions_screen.dart';
import '../features/drm/services/drm_service.dart';

/// Settings screen with app configuration and DRM submissions access
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // DRM Section
          _buildSectionHeader(context, 'DR Forms'),
          _buildSettingsTile(
            context,
            icon: Icons.upload_file_rounded,
            iconColor: AppColors.primaryRed,
            title: 'My Submissions',
            subtitle: 'View submitted DRM forms and sync status',
            onTap: () => _openSubmissions(context),
          ),

          const Divider(height: 32),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.navyBlue,
            title: 'Profile',
            subtitle: 'Manage your nickname and identity',
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Implement profile screen
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.key_rounded,
            iconColor: AppColors.navyBlue,
            title: 'Keys',
            subtitle: 'View and manage your Nostr keys',
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Implement keys screen
            },
          ),

          const Divider(height: 32),

          // Network Section
          _buildSectionHeader(context, 'Network'),
          _buildSettingsTile(
            context,
            icon: Icons.bluetooth_rounded,
            iconColor: AppColors.meshGreen,
            title: 'Bluetooth Mesh',
            subtitle: 'Configure local mesh networking',
            onTap: () {
              HapticFeedback.selectionClick();
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.cloud_outlined,
            iconColor: AppColors.nostrPurple,
            title: 'Nostr Relays',
            subtitle: 'Manage relay connections',
            onTap: () {
              HapticFeedback.selectionClick();
            },
          ),

          const Divider(height: 32),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            iconColor: Theme.of(context).disabledColor,
            title: 'About NupChat',
            subtitle: 'Version 1.0.0',
            onTap: () {
              HapticFeedback.selectionClick();
              _showAboutDialog(context);
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            iconColor: Theme.of(context).disabledColor,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).disabledColor,
      ),
      onTap: onTap,
    );
  }

  void _openSubmissions(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => DrmService()..initialize(),
          child: const DrmSubmissionsScreen(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/nuplogo.png',
              width: 32,
              height: 16,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text('NupChat'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decentralized P2P Messaging',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'NupChat enables secure, decentralized communication using Bluetooth mesh networking and the Nostr protocol.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
}
