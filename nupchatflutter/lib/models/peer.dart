import 'dart:ui';
import 'package:flutter/material.dart' show HSLColor;

/// Represents a peer in the mesh network or Nostr geohash channel
class Peer {
  final String id;
  final String nickname;
  final bool isOnline;
  final DateTime? lastSeen;
  final PeerType type;
  final String? nostrPubKey;
  final bool isVerified;

  const Peer({
    required this.id,
    required this.nickname,
    this.isOnline = false,
    this.lastSeen,
    this.type = PeerType.mesh,
    this.nostrPubKey,
    this.isVerified = false,
  });

  /// Generate a consistent color from peer ID for avatar
  Color get avatarColor {
    final hash = id.hashCode.abs();
    // Use golden ratio for even color distribution
    final hue = (hash * 0.618033988749895) % 1.0;
    return HSLColor.fromAHSL(1.0, hue * 360, 0.65, 0.55).toColor();
  }

  /// Get initials from nickname
  String get initials {
    final parts = nickname.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Short ID for display (first 8 characters)
  String get shortId {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  /// Copy with updated fields
  Peer copyWith({
    String? nickname,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
  }) {
    return Peer(
      id: id,
      nickname: nickname ?? this.nickname,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      type: type,
      nostrPubKey: nostrPubKey,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Peer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Type of peer connection
enum PeerType {
  mesh, // BLE mesh network peer
  nostr, // Nostr geohash channel peer
  hybrid, // Both mesh and Nostr available
}
