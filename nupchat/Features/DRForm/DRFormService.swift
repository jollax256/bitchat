//
// DRFormService.swift
// bitchat
//
// Service to load voter data and manage DR Form submissions
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DRFormService: ObservableObject {
    static let shared = DRFormService()
    
    // MARK: - Published State
    @Published private(set) var isLoadingData = true
    @Published private(set) var isOnline = true
    @Published private(set) var isSyncing = false
    @Published private(set) var submissions: [DRFormSubmission] = []
    
    // MARK: - Data Storage
    private var voterData: VoterDataRoot?
    private let submissionsKey = "dr_form_submissions"
    
    var pendingCount: Int {
        submissions.filter { $0.status == .pending || $0.status == .uploading }.count
    }
    
    private init() {}
    
    // MARK: - Initialization
    
    func initialize() async {
        await loadVoterData()
        await loadSubmissions()
    }
    
    private func loadVoterData() async {
        isLoadingData = true
        
        // Try to load from bundle
        guard let url = Bundle.main.url(forResource: "voter_polling_stations_2021_nested", withExtension: "json") else {
            print("❌ DRFormService: Could not find voter data JSON in bundle")
            isLoadingData = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            voterData = try decoder.decode(VoterDataRoot.self, from: data)
            print("✅ DRFormService: Loaded voter data with \(voterData?.metadata.total_records ?? 0) records")
        } catch {
            print("❌ DRFormService: Error loading voter data: \(error)")
        }
        
        isLoadingData = false
    }
    
    private func loadSubmissions() async {
        if let data = UserDefaults.standard.data(forKey: submissionsKey) {
            do {
                submissions = try JSONDecoder().decode([DRFormSubmission].self, from: data)
            } catch {
                print("❌ DRFormService: Error loading submissions: \(error)")
            }
        }
    }
    
    private func saveSubmissions() {
        do {
            let data = try JSONEncoder().encode(submissions)
            UserDefaults.standard.set(data, forKey: submissionsKey)
        } catch {
            print("❌ DRFormService: Error saving submissions: \(error)")
        }
    }
    
    // MARK: - Location Data Access
    
    func getDistricts() -> [DRDistrict] {
        guard let data = voterData else { return [] }
        return data.districts.map { DRDistrict(id: $0.key, name: $0.value.name) }
            .sorted { $0.name < $1.name }
    }
    
    func getCounties(districtCode: String) -> [DRCounty] {
        guard let district = voterData?.districts[districtCode] else { return [] }
        return district.counties.map { 
            DRCounty(id: $0.key, name: $0.value.name, districtCode: districtCode) 
        }.sorted { $0.name < $1.name }
    }
    
    func getSubCounties(districtCode: String, countyCode: String) -> [DRSubCounty] {
        guard let county = voterData?.districts[districtCode]?.counties[countyCode] else { return [] }
        return county.sub_counties.map { 
            DRSubCounty(id: $0.key, name: $0.value.name, districtCode: districtCode, countyCode: countyCode) 
        }.sorted { $0.name < $1.name }
    }
    
    func getParishes(districtCode: String, countyCode: String, subCountyCode: String) -> [DRParish] {
        guard let subCounty = voterData?.districts[districtCode]?.counties[countyCode]?.sub_counties[subCountyCode] else { return [] }
        return subCounty.parishes.map { 
            DRParish(id: $0.key, name: $0.value.name, districtCode: districtCode, countyCode: countyCode, subCountyCode: subCountyCode) 
        }.sorted { $0.name < $1.name }
    }
    
    func getPollingStations(districtCode: String, countyCode: String, subCountyCode: String, parishCode: String) -> [DRPollingStation] {
        guard let parish = voterData?.districts[districtCode]?.counties[countyCode]?.sub_counties[subCountyCode]?.parishes[parishCode] else { return [] }
        return parish.polling_stations.map { 
            DRPollingStation(
                id: $0.code, 
                name: $0.name, 
                districtCode: districtCode, 
                countyCode: countyCode, 
                subCountyCode: subCountyCode, 
                parishCode: parishCode, 
                voterCount: $0.voter_count
            ) 
        }.sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Submissions
    
    func createSubmission(
        district: DRDistrict,
        county: DRCounty,
        subCounty: DRSubCounty,
        parish: DRParish,
        pollingStation: DRPollingStation,
        imagePath: String
    ) {
        let submission = DRFormSubmission(
            district: district,
            county: county,
            subCounty: subCounty,
            parish: parish,
            pollingStation: pollingStation,
            imagePath: imagePath
        )
        submissions.insert(submission, at: 0)
        saveSubmissions()
    }
}
