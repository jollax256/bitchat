import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../core/theme/app_theme.dart';

class ChannelDrawer extends StatelessWidget {
  final Channel currentChannel;
  final List<Channel> locationChannels;
  final Function(Channel) onChannelSelected;
  final VoidCallback? onSettingsPressed;

  const ChannelDrawer({
    super.key,
    required this.currentChannel,
    required this.locationChannels,
    required this.onChannelSelected,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Premium dark drawer or light
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.ebonyClay : AppColors.white,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // Custom Header using brand colors
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 20,
              24,
              24,
            ),
            color: AppColors.primaryRed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryRed,
                    backgroundImage: const AssetImage(
                      'assets/icons/nupicon-iOS-Default-1024x1024@1x.png',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/nuplogo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Secure P2P Mesh Network",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: isDark ? null : const Color(0xFFFAFAFA),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
                children: [
                  _SectionHeader(title: 'MAIN NETWORKS'),
                  _ChannelTile(
                    channel: Channel.mesh,
                    isSelected: currentChannel.id == Channel.mesh.id,
                    icon: Icons.bluetooth_audio_rounded,
                    onTap: () {
                      onChannelSelected(Channel.mesh);
                      Navigator.pop(context);
                    },
                  ),

                  if (locationChannels.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'LOCATION CHANNELS'),
                    ...locationChannels.map(
                      (channel) => _ChannelTile(
                        channel: channel,
                        isSelected: currentChannel.id == channel.id,
                        icon: Icons.location_on_outlined,
                        onTap: () {
                          onChannelSelected(channel);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? null : Colors.white,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(
                Icons.settings_outlined,
                color: AppColors.navyBlue,
              ),
              title: const Text(
                "Settings",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyBlue,
                ),
              ),
              tileColor: AppColors.navyBlue.withValues(alpha: 0.05),
              onTap: onSettingsPressed,
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.navyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).hintColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected
            ? AppColors.primaryRed.withValues(alpha: 0.1)
            : Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.primaryRed
              : Theme.of(context).iconTheme.color,
        ),
        title: Text(
          channel.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppColors.primaryRed
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: channel.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryRed
                      : AppColors
                            .navyBlue, // Navy blue for unread when not selected
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${channel.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
