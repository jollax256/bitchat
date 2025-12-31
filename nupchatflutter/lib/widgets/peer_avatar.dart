import 'package:flutter/material.dart';
import '../models/peer.dart';
import '../core/theme/app_theme.dart';

class PeerAvatar extends StatelessWidget {
  final Peer peer;
  final double size;
  final bool showOnlineIndicator;
  final VoidCallback? onTap;

  const PeerAvatar({
    super.key,
    required this.peer,
    this.size = 40,
    this.showOnlineIndicator = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate distinct color from name/id
    final seed = peer.id.hashCode;
    final color = HSLColor.fromAHSL(
      1.0,
      (seed.abs() % 360).toDouble(),
      0.4,
      0.5,
    ).toColor();

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, HSLColor.fromColor(color).withLightness(0.45).toColor()],
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              peer.initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),

          if (showOnlineIndicator && peer.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.meshGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.meshGreen.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
