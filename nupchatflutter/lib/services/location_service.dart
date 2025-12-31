import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geohash_plus/geohash_plus.dart';
import '../models/channel.dart';

/// Location Service for geohash-based location channels
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // State
  Position? _currentPosition;
  String? _currentGeohash;
  final Map<GeohashLevel, String> _geohashLevels = {};
  bool _hasPermission = false;
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentGeohash => _currentGeohash;
  bool get hasPermission => _hasPermission;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location: Location services are disabled');
        return false;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location: Permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location: Permission permanently denied');
        return false;
      }

      _hasPermission = true;
      notifyListeners();

      // Get initial position
      await updatePosition();

      return true;
    } catch (e) {
      debugPrint('Location: Error initializing: $e');
      return false;
    }
  }

  /// Update current position and calculate geohash
  Future<void> updatePosition() async {
    if (!_hasPermission) return;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100, // Update every 100 meters
        ),
      );

      if (_currentPosition != null) {
        _calculateGeohashes();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Location: Error getting position: $e');
    }
  }

  /// Calculate geohashes at different precision levels
  void _calculateGeohashes() {
    if (_currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    // Calculate geohash at maximum precision (7 chars for block level)
    final geoHash = GeoHash.encode(lat, lon, precision: 7);
    _currentGeohash = geoHash.hash;

    // Store geohashes at each level
    _geohashLevels[GeohashLevel.block] = geoHash.hash.substring(0, 7);
    _geohashLevels[GeohashLevel.neighborhood] = geoHash.hash.substring(0, 6);
    _geohashLevels[GeohashLevel.city] = geoHash.hash.substring(0, 5);
    _geohashLevels[GeohashLevel.province] = geoHash.hash.substring(0, 4);
    _geohashLevels[GeohashLevel.region] = geoHash.hash.substring(0, 2);

    debugPrint('Location: Current geohash: $_currentGeohash');
  }

  /// Get geohash for a specific level
  String? getGeohash(GeohashLevel level) {
    return _geohashLevels[level];
  }

  /// Get all location channels at current position
  List<Channel> getLocationChannels() {
    if (_currentGeohash == null) return [];

    return GeohashLevel.values
        .map((level) {
          final geohash = _geohashLevels[level];
          if (geohash == null) return null;
          return Channel.location(geohash: geohash, level: level);
        })
        .whereType<Channel>()
        .toList();
  }

  /// Start continuous location updates
  Future<void> startTracking() async {
    if (!_hasPermission) return;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 100,
          ),
        ).listen((position) {
          _currentPosition = position;
          _calculateGeohashes();
          notifyListeners();
        });
  }

  /// Stop location tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two positions in meters
  double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
