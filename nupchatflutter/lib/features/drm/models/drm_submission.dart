import 'dart:convert';

/// Status of a DRM form submission
enum SubmissionStatus {
  pending, // Waiting in queue, not yet attempted
  uploading, // Currently being uploaded
  sent, // Successfully sent to server
  failed, // Upload failed, will retry
}

/// DRM Form Submission model
/// Stores location hierarchy, image paths, and sync status
class DrmSubmission {
  final String id;
  final String districtCode;
  final String district;
  final String countyCode;
  final String county;
  final String subCountyCode;
  final String subCounty;
  final String parishCode;
  final String parish;
  final String pollingStationCode;
  final String pollingStation;
  final String imagePath; // Local file path
  final String? remoteImageUrl; // R2 URL after upload
  final SubmissionStatus status;
  final String timestamp;
  final String? errorMessage;

  const DrmSubmission({
    required this.id,
    required this.districtCode,
    required this.district,
    required this.countyCode,
    required this.county,
    required this.subCountyCode,
    required this.subCounty,
    required this.parishCode,
    required this.parish,
    required this.pollingStationCode,
    required this.pollingStation,
    required this.imagePath,
    this.remoteImageUrl,
    required this.status,
    required this.timestamp,
    this.errorMessage,
  });

  /// Create a copy with updated fields
  DrmSubmission copyWith({
    String? id,
    String? districtCode,
    String? district,
    String? countyCode,
    String? county,
    String? subCountyCode,
    String? subCounty,
    String? parishCode,
    String? parish,
    String? pollingStationCode,
    String? pollingStation,
    String? imagePath,
    String? remoteImageUrl,
    SubmissionStatus? status,
    String? timestamp,
    String? errorMessage,
  }) {
    return DrmSubmission(
      id: id ?? this.id,
      districtCode: districtCode ?? this.districtCode,
      district: district ?? this.district,
      countyCode: countyCode ?? this.countyCode,
      county: county ?? this.county,
      subCountyCode: subCountyCode ?? this.subCountyCode,
      subCounty: subCounty ?? this.subCounty,
      parishCode: parishCode ?? this.parishCode,
      parish: parish ?? this.parish,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      pollingStation: pollingStation ?? this.pollingStation,
      imagePath: imagePath ?? this.imagePath,
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'districtCode': districtCode,
      'district': district,
      'countyCode': countyCode,
      'county': county,
      'subCountyCode': subCountyCode,
      'subCounty': subCounty,
      'parishCode': parishCode,
      'parish': parish,
      'pollingStationCode': pollingStationCode,
      'pollingStation': pollingStation,
      'imagePath': imagePath,
      'remoteImageUrl': remoteImageUrl,
      'status': status.name,
      'timestamp': timestamp,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory DrmSubmission.fromJson(Map<String, dynamic> json) {
    return DrmSubmission(
      id: json['id'] as String,
      districtCode: json['districtCode'] as String,
      district: json['district'] as String,
      countyCode: json['countyCode'] as String,
      county: json['county'] as String,
      subCountyCode: json['subCountyCode'] as String,
      subCounty: json['subCounty'] as String,
      parishCode: json['parishCode'] as String,
      parish: json['parish'] as String,
      pollingStationCode: json['pollingStationCode'] as String,
      pollingStation: json['pollingStation'] as String,
      imagePath: json['imagePath'] as String,
      remoteImageUrl: json['remoteImageUrl'] as String?,
      status: SubmissionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SubmissionStatus.pending,
      ),
      timestamp: json['timestamp'] as String,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Serialize list to JSON string for storage
  static String encodeList(List<DrmSubmission> submissions) {
    return jsonEncode(submissions.map((s) => s.toJson()).toList());
  }

  /// Deserialize list from JSON string
  static List<DrmSubmission> decodeList(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((json) => DrmSubmission.fromJson(json)).toList();
  }
}
