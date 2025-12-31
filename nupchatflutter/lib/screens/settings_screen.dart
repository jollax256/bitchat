import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/nostr_service.dart';
import '../services/tor_service.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nicknameController.text = context.read<ChatService>().nickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7), // iOS Grouped Background
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<ChatService>(
        builder: (context, chatService, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              const SizedBox(height: 10),
              // Profile Header (Centered)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryRed,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        chatService.nickname.isNotEmpty
                            ? chatService.nickname[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Inline edit name?
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _nicknameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: "Your Name",
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) chatService.setNickname(value);
                        },
                      ),
                    ),
                    Text(
                      "Tap to edit nickname",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              _buildSectionHeader('CONNECTIONS'),
              _buildGroupedSection(context, [
                _buildStatusTile(
                  icon: Icons.bluetooth_audio_rounded,
                  title: 'Bluetooth Mesh',
                  subtitle: chatService.isMeshScanning
                      ? 'Scanning nearby devices...'
                      : 'Mesh networking is off',
                  isActive: chatService.isMeshScanning,
                  color: AppColors.meshGreen,
                  onTap: chatService.isMeshScanning
                      ? chatService.stopMeshScanning
                      : chatService.startMeshScanning,
                ),
                _buildStatusTile(
                  icon: Icons.cloud_outlined,
                  title: 'Nostr Relay',
                  subtitle: NostrService().isConnected
                      ? 'Connected to global relays'
                      : 'Disconnected',
                  isActive: NostrService().isConnected,
                  color: AppColors.nostrPurple,
                  showToggle: false,
                ),
                _buildStatusTile(
                  icon: Icons.security,
                  title: 'Tor Network',
                  subtitle: TorService().isConnected
                      ? 'Traffic is anonymized'
                      : 'Direct connection',
                  isActive: TorService().isConnected,
                  color: AppColors.navyBlue,
                  showToggle: false,
                ),
              ]),

              const SizedBox(height: 32),

              _buildSectionHeader('IDENTITY KEYS'),
              _buildGroupedSection(context, [
                _buildCopyTile(
                  'Peer ID',
                  chatService.myPeerId,
                  Icons.fingerprint,
                ),
                if (NostrService().npub != null)
                  _buildCopyTile(
                    'Nostr Public Key',
                    NostrService().npub!,
                    Icons.key,
                  ),
              ]),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset All Data',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/nupicon-iOS-Default-1024x1024@1x.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NupChat v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedSection(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required Color color,
    bool showToggle = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
      ),
      trailing: showToggle
          ? Switch.adaptive(
              value: isActive,
              activeColor: color,
              onChanged: (_) => onTap?.call(),
            )
          : null, // Maybe show checkmark?
    );
  }

  Widget _buildCopyTile(String label, String value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.ebonyClay.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.ebonyClay, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy_rounded, size: 20),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          HapticFeedback.lightImpact();
        },
      ),
    );
  }
}
