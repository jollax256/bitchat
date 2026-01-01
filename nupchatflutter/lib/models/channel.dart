/// Represents a chat channel (mesh or location-based)
class Channel {
  final String id;
  final String name;
  final ChannelType type;
  final String? geohash;
  final int unreadCount;
  final DateTime? lastActivity;

  const Channel({
    required this.id,
    required this.name,
    required this.type,
    this.geohash,
    this.unreadCount = 0,
    this.lastActivity,
  });

  /// Mesh channel singleton
  static const mesh = Channel(
    id: 'mesh',
    name: 'mesh #bluetooth',
    type: ChannelType.mesh,
  );

  /// Create a location channel
  factory Channel.location({
    required String geohash,
    required GeohashLevel level,
  }) {
    return Channel(
      id: 'geo:$geohash',
      name: '${level.displayName} #${geohash.toLowerCase()}',
      type: ChannelType.location,
      geohash: geohash,
    );
  }

  /// Get the display icon for this channel
  String get icon {
    switch (type) {
      case ChannelType.mesh:
        return '📡';
      case ChannelType.location:
        return '📍';
    }
  }

  /// Copy with updated fields
  Channel copyWith({int? unreadCount, DateTime? lastActivity}) {
    return Channel(
      id: id,
      name: name,
      type: type,
      geohash: geohash,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Type of channel
enum ChannelType {
  mesh, // BLE Bluetooth mesh
  location, // Nostr geohash location
}

/// Geohash precision levels (matches iOS GeohashChannelLevel)
enum GeohashLevel {
  building, // 8 chars - building
  block, // 7 chars - city block
  neighborhood, // 6 chars - district
  city, // 5 chars - city
  province, // 4 chars - state/province
  region, // 2 chars - country/region
}

extension GeohashLevelExtension on GeohashLevel {
  String get displayName {
    switch (this) {
      case GeohashLevel.building:
        return 'building';
      case GeohashLevel.block:
        return 'block';
      case GeohashLevel.neighborhood:
        return 'neighborhood';
      case GeohashLevel.city:
        return 'city';
      case GeohashLevel.province:
        return 'province';
      case GeohashLevel.region:
        return 'region';
    }
  }

  int get precision {
    switch (this) {
      case GeohashLevel.building:
        return 8;
      case GeohashLevel.block:
        return 7;
      case GeohashLevel.neighborhood:
        return 6;
      case GeohashLevel.city:
        return 5;
      case GeohashLevel.province:
        return 4;
      case GeohashLevel.region:
        return 2;
    }
  }
}
