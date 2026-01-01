//
// DRFormModels.swift
// bitchat
//
// Location data models for DR Forms - hierarchical location selection
// District → County → Sub-county → Parish → Polling Station
//

import Foundation

// MARK: - Location Models

struct DRDistrict: Identifiable, Hashable {
    let id: String  // code
    let name: String
    
    var code: String { id }
}

struct DRCounty: Identifiable, Hashable {
    let id: String  // code
    let name: String
    let districtCode: String
    
    var code: String { id }
}

struct DRSubCounty: Identifiable, Hashable {
    let id: String  // code
    let name: String
    let districtCode: String
    let countyCode: String
    
    var code: String { id }
}

struct DRParish: Identifiable, Hashable {
    let id: String  // code
    let name: String
    let districtCode: String
    let countyCode: String
    let subCountyCode: String
    
    var code: String { id }
}

struct DRPollingStation: Identifiable, Hashable {
    let id: String  // code
    let name: String
    let districtCode: String
    let countyCode: String
    let subCountyCode: String
    let parishCode: String
    let voterCount: Int
    
    var code: String { id }
    
    var displayName: String {
        name.isEmpty ? "Station \(code)" : name
    }
}

// MARK: - Submission Model

enum DRSubmissionStatus: String, Codable {
    case pending
    case uploading
    case sent
    case failed
}

struct DRFormSubmission: Identifiable, Codable {
    let id: String
    let districtCode: String
    let district: String
    let countyCode: String
    let county: String
    let subCountyCode: String
    let subCounty: String
    let parishCode: String
    let parish: String
    let pollingStationCode: String
    let pollingStation: String
    let imagePath: String
    var remoteImageUrl: String?
    var status: DRSubmissionStatus
    let timestamp: Date
    var errorMessage: String?
    
    init(
        district: DRDistrict,
        county: DRCounty,
        subCounty: DRSubCounty,
        parish: DRParish,
        pollingStation: DRPollingStation,
        imagePath: String
    ) {
        self.id = UUID().uuidString
        self.districtCode = district.code
        self.district = district.name
        self.countyCode = county.code
        self.county = county.name
        self.subCountyCode = subCounty.code
        self.subCounty = subCounty.name
        self.parishCode = parish.code
        self.parish = parish.name
        self.pollingStationCode = pollingStation.code
        self.pollingStation = pollingStation.displayName
        self.imagePath = imagePath
        self.status = .pending
        self.timestamp = Date()
    }
}

// MARK: - JSON Parsing Models

struct VoterDataRoot: Codable {
    let metadata: VoterMetadata
    let districts: [String: DistrictData]
}

struct VoterMetadata: Codable {
    let title: String
    let source: String
    let total_records: Int
}

struct DistrictData: Codable {
    let name: String
    let counties: [String: CountyData]
}

struct CountyData: Codable {
    let name: String
    let sub_counties: [String: SubCountyData]
}

struct SubCountyData: Codable {
    let name: String
    let parishes: [String: ParishData]
}

struct ParishData: Codable {
    let name: String
    let polling_stations: [PollingStationData]
}

struct PollingStationData: Codable {
    let code: String
    let name: String
    let voter_count: Int
}
