//
// DRSubmissionView.swift
// NupChat
//
// Screen showing all DR form submissions with their sync status
//

import SwiftUI
import QuickLook

struct DRSubmissionView: View {
    @StateObject private var service = DRFormService.shared
    @State private var selectedSubmission: DRFormSubmission?
    
    var body: some View {
        List {
            if service.submissions.isEmpty {
                emptyState
            } else {
                ForEach(service.submissions) { submission in
                    SubmissionRow(submission: submission)
                        .onTapGesture {
                            selectedSubmission = submission
                        }
                }
            }
        }
        .navigationTitle("My Submissions")
        .sheet(item: $selectedSubmission) { submission in
            SubmissionDetailView(submission: submission)
        }
        .toolbar {
            if service.pendingCount > 0 && service.isOnline && !service.isSyncing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Trigger sync
                        // service.syncNow() // Implement if available
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No submissions yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Submit a DR form to see it here")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
        .listRowBackground(Color.clear)
    }
}

struct SubmissionRow: View {
    let submission: DRFormSubmission
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let image = UIImage(contentsOfFile: submission.imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(submission.district) - \(submission.pollingStation)")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(submission.county) › \(submission.subCounty) › \(submission.parish)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(submission.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: submission.status)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: DRSubmissionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(statusText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.1))
        .foregroundColor(backgroundColor)
        .clipShape(Capsule())
    }
    
    var iconName: String {
        switch status {
        case .pending: return "clock"
        case .uploading: return "arrow.up.circle"
        case .sent: return "checkmark.circle"
        case .failed: return "exclamationmark.circle"
        }
    }
    
    var statusText: String {
        switch status {
        case .pending: return "Cached"
        case .uploading: return "Sending"
        case .sent: return "Sent"
        case .failed: return "Failed"
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .uploading: return .blue
        case .sent: return .green
        case .failed: return .red
        }
    }
}

struct SubmissionDetailView: View {
    let submission: DRFormSubmission
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let image = UIImage(contentsOfFile: submission.imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Status
                    HStack {
                        Text("Status")
                            .font(.headline)
                        Spacer()
                        StatusBadge(status: submission.status)
                    }
                    
                    Divider()
                    
                    // Location Details
                    Group {
                        DetailRow(label: "District", value: submission.district)
                        DetailRow(label: "County", value: submission.county)
                        DetailRow(label: "Sub-County", value: submission.subCounty)
                        DetailRow(label: "Parish", value: submission.parish)
                        DetailRow(label: "Polling Station", value: submission.pollingStation)
                    }
                    
                    Divider()
                    
                    DetailRow(label: "Submitted", value: submission.timestamp.formatted(date: .long, time: .shortened))
                    
                    if let error = submission.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.body)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Submission Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
