import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/location_data.dart';

/// Service for lazy-loading and parsing the large polling stations JSON file.
/// Uses isolate (compute) for background parsing to prevent UI jank.
class LocationDataService {
  static LocationDataService? _instance;
  static LocationDataService get instance =>
      _instance ??= LocationDataService._();

  LocationDataService._();

  // Cached parsed data
  Map<String, dynamic>? _rawData;
  List<District>? _districts;
  bool _isLoading = false;

  /// Check if data is loaded
  bool get isLoaded => _rawData != null;

  /// Load and parse the JSON file in a background isolate
  Future<void> loadData() async {
    if (_rawData != null || _isLoading) return;

    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/jsondata/voter_polling_stations_2021_nested.json',
      );

      // Parse in background isolate to prevent UI jank
      _rawData = await compute(_parseJson, jsonString);
      _districts = _extractDistricts(_rawData!);
    } finally {
      _isLoading = false;
    }
  }

  /// Parse JSON in isolate
  static Map<String, dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Extract districts from parsed data
  List<District> _extractDistricts(Map<String, dynamic> data) {
    final districtsData = data['districts'] as Map<String, dynamic>? ?? {};
    return districtsData.entries.map((entry) {
      final districtMap = entry.value as Map<String, dynamic>;
      return District(
        code: entry.key,
        name: districtMap['name'] as String? ?? 'Unknown',
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get all districts (sorted alphabetically)
  List<District> getDistricts() {
    return _districts ?? [];
  }

  /// Get counties for a specific district
  List<County> getCounties(String districtCode) {
    if (_rawData == null) return [];

    final districtsData = _rawData!['districts'] as Map<String, dynamic>? ?? {};
    final districtData = districtsData[districtCode] as Map<String, dynamic>?;
    if (districtData == null) return [];

    final countiesData =
        districtData['counties'] as Map<String, dynamic>? ?? {};
    return countiesData.entries.map((entry) {
      final countyMap = entry.value as Map<String, dynamic>;
      return County(
        code: entry.key,
        name: countyMap['name'] as String? ?? 'Unknown',
        districtCode: districtCode,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get sub-counties for a specific county
  List<SubCounty> getSubCounties(String districtCode, String countyCode) {
    if (_rawData == null) return [];

    final districtsData = _rawData!['districts'] as Map<String, dynamic>? ?? {};
    final districtData = districtsData[districtCode] as Map<String, dynamic>?;
    if (districtData == null) return [];

    final countiesData =
        districtData['counties'] as Map<String, dynamic>? ?? {};
    final countyData = countiesData[countyCode] as Map<String, dynamic>?;
    if (countyData == null) return [];

    final subCountiesData =
        countyData['sub_counties'] as Map<String, dynamic>? ?? {};
    return subCountiesData.entries.map((entry) {
      final subCountyMap = entry.value as Map<String, dynamic>;
      return SubCounty(
        code: entry.key,
        name: subCountyMap['name'] as String? ?? 'Unknown',
        districtCode: districtCode,
        countyCode: countyCode,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get parishes for a specific sub-county
  List<Parish> getParishes(
    String districtCode,
    String countyCode,
    String subCountyCode,
  ) {
    if (_rawData == null) return [];

    final districtsData = _rawData!['districts'] as Map<String, dynamic>? ?? {};
    final districtData = districtsData[districtCode] as Map<String, dynamic>?;
    if (districtData == null) return [];

    final countiesData =
        districtData['counties'] as Map<String, dynamic>? ?? {};
    final countyData = countiesData[countyCode] as Map<String, dynamic>?;
    if (countyData == null) return [];

    final subCountiesData =
        countyData['sub_counties'] as Map<String, dynamic>? ?? {};
    final subCountyData =
        subCountiesData[subCountyCode] as Map<String, dynamic>?;
    if (subCountyData == null) return [];

    final parishesData =
        subCountyData['parishes'] as Map<String, dynamic>? ?? {};
    return parishesData.entries.map((entry) {
      final parishMap = entry.value as Map<String, dynamic>;
      return Parish(
        code: entry.key,
        name: parishMap['name'] as String? ?? 'Unknown',
        districtCode: districtCode,
        countyCode: countyCode,
        subCountyCode: subCountyCode,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get polling stations for a specific parish
  List<PollingStation> getPollingStations(
    String districtCode,
    String countyCode,
    String subCountyCode,
    String parishCode,
  ) {
    if (_rawData == null) return [];

    final districtsData = _rawData!['districts'] as Map<String, dynamic>? ?? {};
    final districtData = districtsData[districtCode] as Map<String, dynamic>?;
    if (districtData == null) return [];

    final countiesData =
        districtData['counties'] as Map<String, dynamic>? ?? {};
    final countyData = countiesData[countyCode] as Map<String, dynamic>?;
    if (countyData == null) return [];

    final subCountiesData =
        countyData['sub_counties'] as Map<String, dynamic>? ?? {};
    final subCountyData =
        subCountiesData[subCountyCode] as Map<String, dynamic>?;
    if (subCountyData == null) return [];

    final parishesData =
        subCountyData['parishes'] as Map<String, dynamic>? ?? {};
    final parishData = parishesData[parishCode] as Map<String, dynamic>?;
    if (parishData == null) return [];

    final stationsList = parishData['polling_stations'] as List<dynamic>? ?? [];
    return stationsList.map((station) {
      final stationMap = station as Map<String, dynamic>;
      return PollingStation(
        code: stationMap['code'] as String? ?? '',
        name: stationMap['name'] as String? ?? 'Unknown',
        voterCount: stationMap['voter_count'] as int? ?? 0,
        districtCode: districtCode,
        countyCode: countyCode,
        subCountyCode: subCountyCode,
        parishCode: parishCode,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
