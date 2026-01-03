//
// DRFormService.swift
// bitchat
//
// Service to load voter data and manage DR Form submissions
//

import Foundation
import SwiftUI
import Combine
import Network

@MainActor
final class DRFormService: ObservableObject {
    static let shared = DRFormService()
    
    // Server configuration
    private let serverBaseUrl = "https://nupchatsvr.sntlpjtdi.workers.dev"
    
    // MARK: - Published State
    @Published private(set) var isLoadingData = true
    @Published private(set) var isOnline = true
    @Published private(set) var isSyncing = false
    @Published private(set) var submissions: [DRFormSubmission] = []
    
    // MARK: - Data Storage
    private var voterData: VoterDataRoot?
    private let submissionsKey = "dr_form_submissions"
    
    // MARK: - Network Monitor
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var pendingCount: Int {
        submissions.filter { $0.status == .pending || $0.status == .uploading || $0.status == .failed }.count
    }
    
    private init() {
        startNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        await loadVoterData()
        await loadSubmissions()
        
        // Try initial sync if online
        if isOnline {
            await syncPendingSubmissions()
        }
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = path.status == .satisfied
                
                // If we just came online, trigger sync
                if wasOffline && self.isOnline {
                    await self.syncPendingSubmissions()
                }
            }
        }
        monitor.start(queue: queue)
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
    
    // MARK: - Update Helpers
    
    private func updateSubmissionStatus(_ id: String, status: DRSubmissionStatus, remoteUrl: String? = nil, errorMessage: String? = nil) {
        if let index = submissions.firstIndex(where: { $0.id == id }) {
            var submission = submissions[index]
            submission.status = status
            if let url = remoteUrl {
                submission.remoteImageUrl = url
            }
            if let error = errorMessage {
                submission.errorMessage = error
            }
            submissions[index] = submission
            saveSubmissions()
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
    
    // MARK: - Submissions Logic
    
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
        
        // Try to sync immediately if online
        if isOnline {
            Task {
                await syncPendingSubmissions()
            }
        }
    }
    
    func deleteSubmission(_ id: String) {
        if let index = submissions.firstIndex(where: { $0.id == id }) {
            submissions.remove(at: index)
            saveSubmissions()
        }
    }
    
    func syncPendingSubmissions() async {
        guard !isSyncing && isOnline else { return }
        
        let pending = submissions.filter { $0.status == .pending || $0.status == .failed }
        guard !pending.isEmpty else { return }
        
        isSyncing = true
        
        for submission in pending {
            await uploadSubmission(submission)
        }
        
        isSyncing = false
    }
    
    private func uploadSubmission(_ submission: DRFormSubmission) async {
        // 1. Mark as uploading
        updateSubmissionStatus(submission.id, status: .uploading)
        
        do {
            // 2. Upload Image
            let imageUrl = try await uploadImage(at: submission.imagePath)
            
            // 3. Submit Form Data
            try await submitFormData(submission: submission, imageUrl: imageUrl)
            
            // 4. Mark as Sent
            updateSubmissionStatus(submission.id, status: .sent, remoteUrl: imageUrl)
            
        } catch {
            print("❌ Upload failed: \(error)")
            updateSubmissionStatus(submission.id, status: .failed, errorMessage: error.localizedDescription)
        }
    }
    
    private func uploadImage(at path: String) async throws -> String {
        // Construct upload URL
        guard let url = URL(string: "\(serverBaseUrl)/api/drm/upload-image") else {
            throw URLError(.badURL)
        }
        
        // Load image data
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
             throw NSError(domain: "DRFormService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not read image file"])
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create HTTP body
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "DRFormService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Server returned error during image upload"])
        }
        
        // Parse response
        struct UploadResponse: Codable {
            let success: Bool
            let url: String
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        guard uploadResponse.success else {
             throw NSError(domain: "DRFormService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Server reported failure in response"])
        }
        
        return uploadResponse.url
    }
    
    private func submitFormData(submission: DRFormSubmission, imageUrl: String) async throws {
        guard let url = URL(string: "\(serverBaseUrl)/api/drm/submissions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create payload matching Flutter implementation and server expectation
        let payload: [String: Any] = [
            "id": submission.id,
            "districtCode": submission.districtCode,
            "districtName": submission.district,
            "countyCode": submission.countyCode,
            "countyName": submission.county,
            "subCountyCode": submission.subCountyCode,
            "subCountyName": submission.subCounty,
            "parishCode": submission.parishCode,
            "parishName": submission.parish,
            "pollingStationCode": submission.pollingStationCode,
            "pollingStationName": submission.pollingStation,
            "imageUrl": imageUrl,
            "timestamp": ISO8601DateFormatter().string(from: submission.timestamp)
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "DRFormService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Server returned error during form submission"])
        }
    }
}
