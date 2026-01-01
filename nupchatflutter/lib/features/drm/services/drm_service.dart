import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/drm_submission.dart';
import '../models/location_data.dart';
import 'location_data_service.dart';
import 'offline_service.dart';

/// Main DRM service combining location data and submission management
class DrmService extends ChangeNotifier {
  final OfflineService _offlineService;
  final LocationDataService _locationDataService;

  // Server configuration - update this to your deployed worker URL
  static const String _serverBaseUrl =
      'https://nupchatsvr.YOUR_SUBDOMAIN.workers.dev';

  bool _isInitialized = false;
  bool _isLoadingData = false;

  DrmService({
    OfflineService? offlineService,
    LocationDataService? locationDataService,
  }) : _offlineService = offlineService ?? OfflineService(),
       _locationDataService =
           locationDataService ?? LocationDataService.instance;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Whether location data is loading
  bool get isLoadingData => _isLoadingData;

  /// All submissions from offline service
  List<DrmSubmission> get submissions => _offlineService.submissions;

  /// Whether currently online
  bool get isOnline => _offlineService.isOnline;

  /// Whether currently syncing
  bool get isSyncing => _offlineService.isSyncing;

  /// Pending submissions count
  int get pendingCount => _offlineService.pendingCount;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoadingData = true;
    notifyListeners();

    try {
      await _offlineService.initialize();
      await _locationDataService.loadData();

      // Forward offline service notifications
      _offlineService.addListener(_onOfflineServiceChanged);

      _isInitialized = true;
    } finally {
      _isLoadingData = false;
    }

    notifyListeners();
  }

  void _onOfflineServiceChanged() {
    notifyListeners();
  }

  // ==================== Location Data Methods ====================

  /// Get all districts
  List<District> getDistricts() => _locationDataService.getDistricts();

  /// Get counties for a district
  List<County> getCounties(String districtCode) =>
      _locationDataService.getCounties(districtCode);

  /// Get sub-counties for a county
  List<SubCounty> getSubCounties(String districtCode, String countyCode) =>
      _locationDataService.getSubCounties(districtCode, countyCode);

  /// Get parishes for a sub-county
  List<Parish> getParishes(
    String districtCode,
    String countyCode,
    String subCountyCode,
  ) =>
      _locationDataService.getParishes(districtCode, countyCode, subCountyCode);

  /// Get polling stations for a parish
  List<PollingStation> getPollingStations(
    String districtCode,
    String countyCode,
    String subCountyCode,
    String parishCode,
  ) => _locationDataService.getPollingStations(
    districtCode,
    countyCode,
    subCountyCode,
    parishCode,
  );

  // ==================== Submission Methods ====================

  /// Create and save a new DRM submission
  Future<DrmSubmission> createSubmission({
    required District district,
    required County county,
    required SubCounty subCounty,
    required Parish parish,
    required PollingStation pollingStation,
    required File imageFile,
  }) async {
    // Copy image to app storage
    final storageDir = await _offlineService.getImageStorageDirectory();
    final uuid = const Uuid().v4();
    final extension = imageFile.path.split('.').last;
    final newPath = '${storageDir.path}/$uuid.$extension';
    await imageFile.copy(newPath);

    // Create submission
    final submission = DrmSubmission(
      id: uuid,
      districtCode: district.code,
      district: district.name,
      countyCode: county.code,
      county: county.name,
      subCountyCode: subCounty.code,
      subCounty: subCounty.name,
      parishCode: parish.code,
      parish: parish.name,
      pollingStationCode: pollingStation.code,
      pollingStation: pollingStation.name,
      imagePath: newPath,
      status: SubmissionStatus.pending,
      timestamp: DateTime.now().toIso8601String(),
    );

    await _offlineService.addSubmission(submission);
    return submission;
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    await _offlineService.syncPendingSubmissions();
  }

  /// Upload image to server and get URL
  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$_serverBaseUrl/api/drm/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody);
        return json['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Submit form data to server
  Future<bool> submitFormData(DrmSubmission submission, String imageUrl) async {
    try {
      final uri = Uri.parse('$_serverBaseUrl/api/drm/submissions');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': submission.id,
          'districtCode': submission.districtCode,
          'districtName': submission.district,
          'countyCode': submission.countyCode,
          'countyName': submission.county,
          'subCountyCode': submission.subCountyCode,
          'subCountyName': submission.subCounty,
          'parishCode': submission.parishCode,
          'parishName': submission.parish,
          'pollingStationCode': submission.pollingStationCode,
          'pollingStationName': submission.pollingStation,
          'imageUrl': imageUrl,
          'timestamp': submission.timestamp,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error submitting form data: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _offlineService.removeListener(_onOfflineServiceChanged);
    _offlineService.dispose();
    super.dispose();
  }
}
