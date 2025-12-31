/// Centralized configuration constants for transport and UI.
/// Ported from iOS TransportConfig.swift
class TransportConfig {
  // BLE / Protocol
  static const int bleDefaultFragmentSize = 469;
  static const int messageTTLDefault = 7;
  static const int bleMaxInFlightAssemblies = 128;
  static const int bleHighDegreeThreshold = 6;
  static const int bleMaxConcurrentTransfers = 2;

  // UI / Storage Caps
  static const int privateChatCap = 1337;
  static const int meshTimelineCap = 1337;
  static const int geoTimelineCap = 1337;

  // Timers
  static const double networkResetGraceSeconds = 600;
  static const double basePublicFlushInterval = 0.08;

  // Nostr
  static const double nostrReadAckInterval = 0.35;
  static const int nostrGeoRelayCount = 5;
  static const double nostrGeohashInitialLookbackSeconds = 3600;
  static const int nostrGeohashInitialLimit = 200;
  static const double nostrDMSubscribeLookbackSeconds = 86400;

  // UI thresholds
  static const double uiLateInsertThreshold = 15.0;
  static const int uiProcessedNostrEventsCap = 2000;
  static const double uiChannelInactivityThreshold = 9 * 60;

  // Message deduplication
  static const double messageDedupMaxAgeSeconds = 300;
  static const int messageDedupMaxCount = 1000;

  // BLE operational
  static const double bleConnectTimeoutSeconds = 8.0;
  static const double blePeerInactivityTimeout = 8.0;
  static const double bleReachabilityRetention = 21.0;

  // Geohash channel levels
  static const Map<String, int> geohashLevels = {
    'block': 7,
    'neighborhood': 6,
    'city': 5,
    'province': 4,
    'region': 2,
  };
}
