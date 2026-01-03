//
// DRFormView.swift
// bitchat
//
// DR Form submission screen with cascading location dropdowns and image upload
//

import SwiftUI
import PhotosUI

struct DRFormView: View {
    @StateObject private var service = DRFormService.shared
    
    // Location selections
    @State private var selectedDistrict: DRDistrict?
    @State private var selectedCounty: DRCounty?
    @State private var selectedSubCounty: DRSubCounty?
    @State private var selectedParish: DRParish?
    @State private var selectedPollingStation: DRPollingStation?
    
    // Image
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    
    // State
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Offline banner
                if !service.isOnline {
                    offlineBanner
                }
                
                // Pending submissions indicator
                if service.pendingCount > 0 {
                    pendingBanner
                }
                
                // Header
                headerSection
                
                // Location dropdowns
                locationSection
                
                // Image section
                imageSection
                
                // Submit button
                submitButton
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("DR Forms")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await service.initialize()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imagePickerSource)
                .ignoresSafeArea()
        }
        .alert("DR Forms", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if service.isLoadingData {
                loadingOverlay
            }
        }
    }
    
    // MARK: - Components
    
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Offline mode: Forms will be cached and synced when connected")
                .font(.caption)
        }
        .foregroundColor(.orange)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var pendingBanner: some View {
        HStack {
            if service.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "cloud.fill")
            }
            Text(service.isSyncing 
                ? "Syncing \(service.pendingCount) submission(s)..." 
                : "\(service.pendingCount) submission(s) pending")
                .font(.caption)
        }
        .foregroundColor(.blue)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DR Forms Submission")
                .font(.title2)
                .fontWeight(.bold)
            Text("Select location and upload the DR form image")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var locationSection: some View {
        VStack(spacing: 16) {
            // District
            LocationPicker(
                title: "District",
                selection: $selectedDistrict,
                items: service.getDistricts(),
                itemLabel: { $0.name },
                onChanged: {
                    selectedCounty = nil
                    selectedSubCounty = nil
                    selectedParish = nil
                    selectedPollingStation = nil
                }
            )
            
            // County
            LocationPicker(
                title: "County",
                selection: $selectedCounty,
                items: selectedDistrict.map { service.getCounties(districtCode: $0.code) } ?? [],
                itemLabel: { $0.name },
                isEnabled: selectedDistrict != nil,
                onChanged: {
                    selectedSubCounty = nil
                    selectedParish = nil
                    selectedPollingStation = nil
                }
            )
            
            // Sub-County
            LocationPicker(
                title: "Sub-County",
                selection: $selectedSubCounty,
                items: (selectedDistrict != nil && selectedCounty != nil) 
                    ? service.getSubCounties(districtCode: selectedDistrict!.code, countyCode: selectedCounty!.code) 
                    : [],
                itemLabel: { $0.name },
                isEnabled: selectedCounty != nil,
                onChanged: {
                    selectedParish = nil
                    selectedPollingStation = nil
                }
            )
            
            // Parish
            LocationPicker(
                title: "Parish",
                selection: $selectedParish,
                items: (selectedDistrict != nil && selectedCounty != nil && selectedSubCounty != nil)
                    ? service.getParishes(districtCode: selectedDistrict!.code, countyCode: selectedCounty!.code, subCountyCode: selectedSubCounty!.code)
                    : [],
                itemLabel: { $0.name },
                isEnabled: selectedSubCounty != nil,
                onChanged: {
                    selectedPollingStation = nil
                }
            )
            
            // Polling Station
            LocationPicker(
                title: "Polling Station",
                selection: $selectedPollingStation,
                items: (selectedDistrict != nil && selectedCounty != nil && selectedSubCounty != nil && selectedParish != nil)
                    ? service.getPollingStations(districtCode: selectedDistrict!.code, countyCode: selectedCounty!.code, subCountyCode: selectedSubCounty!.code, parishCode: selectedParish!.code)
                    : [],
                itemLabel: { $0.displayName },
                isEnabled: selectedParish != nil,
                onChanged: { }
            )
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DR Forms Image")
                .font(.headline)
            
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                    
                    Button {
                        selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                noImagePlaceholder
            }
            
            // Image picker buttons
            HStack(spacing: 12) {
                Button {
                    imagePickerSource = .camera
                    showImagePicker = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    imagePickerSource = .photoLibrary
                    showImagePicker = true
                } label: {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var noImagePlaceholder: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No image selected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var submitButton: some View {
        Button {
            submitForm()
        } label: {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Submit DR Forms")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(canSubmit ? Color.red : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(!canSubmit || isSubmitting)
    }
    
    private var loadingOverlay: some View {
        VStack {
            ProgressView()
            Text("Loading location data...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // MARK: - Helpers
    
    private var canSubmit: Bool {
        selectedDistrict != nil &&
        selectedCounty != nil &&
        selectedSubCounty != nil &&
        selectedParish != nil &&
        selectedPollingStation != nil &&
        selectedImage != nil
    }
    
    private func submitForm() {
        guard canSubmit else {
            alertMessage = "Please complete all fields and select an image"
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        // Save image to documents directory
        let imagePath = saveImage(selectedImage!)
        
        service.createSubmission(
            district: selectedDistrict!,
            county: selectedCounty!,
            subCounty: selectedSubCounty!,
            parish: selectedParish!,
            pollingStation: selectedPollingStation!,
            imagePath: imagePath
        )
        
        // Reset image
        selectedImage = nil
        isSubmitting = false
        
        alertMessage = service.isOnline
            ? "Submission saved and uploading..."
            : "Submission cached. Will upload when online."
        showAlert = true
    }
    
    private func saveImage(_ image: UIImage) -> String {
        let filename = UUID().uuidString + ".jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(filename)
        
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: filePath)
        }
        
        return filePath.path
    }
}

// MARK: - Location Picker Component

struct LocationPicker<T: Identifiable & Hashable>: View {
    let title: String
    @Binding var selection: T?
    let items: [T]
    let itemLabel: (T) -> String
    var isEnabled: Bool = true
    var onChanged: () -> Void = {}
    
    @State private var showSheet = false
    @State private var searchText = ""
    
    private var filteredItems: [T] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { itemLabel($0).localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button {
                showSheet = true
            } label: {
                HStack {
                    Text(selection.map(itemLabel) ?? (isEnabled ? "Select \(title)" : "Select \(title.lowercased()) above first"))
                        .foregroundColor(selection != nil ? Color.primary : Color.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.6)
        }
        .sheet(isPresented: $showSheet) {
            NavigationView {
                List(filteredItems) { item in
                    Button {
                        selection = item
                        onChanged()
                        showSheet = false
                    } label: {
                        HStack {
                            Text(itemLabel(item))
                            Spacer()
                            if selection == item {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                .searchable(text: $searchText, prompt: "Search \(title.lowercased())...")
                .navigationTitle("Select \(title)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showSheet = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        DRFormView()
    }
}
