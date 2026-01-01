import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drm_submission.dart';

/// Service for managing offline storage and sync of DRM submissions
class OfflineService extends ChangeNotifier {
  static const String _storageKey = 'drm_submissions';

  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;

  List<DrmSubmission> _submissions = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  /// All submissions
  List<DrmSubmission> get submissions => List.unmodifiable(_submissions);

  /// Current network status
  bool get isOnline => _isOnline;

  /// Whether currently syncing
  bool get isSyncing => _isSyncing;

  /// Pending submissions count
  int get pendingCount => _submissions
      .where(
        (s) =>
            s.status == SubmissionStatus.pending ||
            s.status == SubmissionStatus.failed,
      )
      .length;

  /// Initialize service - load from storage and start connectivity monitoring
  Future<void> initialize() async {
    await _loadFromStorage();
    _startConnectivityMonitoring();
  }

  /// Start monitoring network connectivity
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      final wasOffline = !_isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);

      // If we just came online, trigger sync
      if (wasOffline && _isOnline) {
        syncPendingSubmissions();
      }

      notifyListeners();
    });

    // Check initial status
    _connectivity.checkConnectivity().then((List<ConnectivityResult> result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  /// Load submissions from local storage
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        _submissions = DrmSubmission.decodeList(jsonString);
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading submissions: $e');
        _submissions = [];
      }
    }
  }

  /// Save submissions to local storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = DrmSubmission.encodeList(_submissions);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Add a new submission (initially pending)
  Future<void> addSubmission(DrmSubmission submission) async {
    _submissions.insert(0, submission);
    await _saveToStorage();
    notifyListeners();

    // Try to sync immediately if online
    if (_isOnline) {
      syncPendingSubmissions();
    }
  }

  /// Update a submission status
  Future<void> _updateSubmission(
    String id,
    SubmissionStatus status, {
    String? remoteUrl,
    String? error,
  }) async {
    final index = _submissions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    _submissions[index] = _submissions[index].copyWith(
      status: status,
      remoteImageUrl: remoteUrl,
      errorMessage: error,
    );
    await _saveToStorage();
    notifyListeners();
  }

  /// Sync all pending submissions to server
  Future<void> syncPendingSubmissions() async {
    if (_isSyncing || !_isOnline) return;

    final pending = _submissions
        .where(
          (s) =>
              s.status == SubmissionStatus.pending ||
              s.status == SubmissionStatus.failed,
        )
        .toList();

    if (pending.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    for (final submission in pending) {
      await _uploadSubmission(submission);
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Upload a single submission
  Future<void> _uploadSubmission(DrmSubmission submission) async {
    try {
      // Mark as uploading
      await _updateSubmission(submission.id, SubmissionStatus.uploading);

      // TODO: Implement actual upload logic
      // For now, simulate upload delay
      await Future.delayed(const Duration(seconds: 2));

      // Mark as sent (in real implementation, this would happen after successful API call)
      await _updateSubmission(submission.id, SubmissionStatus.sent);
    } catch (e) {
      debugPrint('Upload failed: $e');
      await _updateSubmission(
        submission.id,
        SubmissionStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Get the app's documents directory for storing images
  Future<Directory> getImageStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/drm_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// Clean up
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
