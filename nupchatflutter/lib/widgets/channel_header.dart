import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../core/theme/app_theme.dart';

class ChannelHeader extends StatelessWidget {
  final Channel channel;
  final int peerCount;
  final bool isScanning;
  final VoidCallback? onTap;
  final VoidCallback? onPeersPressed;

  const ChannelHeader({
    super.key,
    required this.channel,
    this.peerCount = 0,
    this.isScanning = false,
    this.onTap,
    this.onPeersPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            channel.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17, // Apple standard for nav title
              fontFamily: 'Outfit',
            ),
          ),

          GestureDetector(
            onTap: onPeersPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStatusRow(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    final Color statusColor = isScanning
        ? AppColors.warning
        : (peerCount > 0 ? AppColors.success : Colors.grey);

    final String statusText = isScanning
        ? 'Scanning...'
        : '$peerCount active ${peerCount == 1 ? 'peer' : 'peers'}';

    // Key needed for AnimatedSwitcher transition to work on text change
    return Row(
      key: ValueKey<String>(statusText),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dot
        // Removed raw Container, maybe use text style for simplicity or icon
        if (!isScanning) // Don't show dot if scanning text says scanning... or maybe keep it?
          Container(
            margin: const EdgeInsets.only(right: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),

        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: statusColor, // Match text to status color for status line
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
