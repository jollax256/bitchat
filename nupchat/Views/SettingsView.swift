//
// SettingsView.swift
// NupChat
//
// Settings screen with app configuration and DRM submissions access
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAboutAlert = false
    @State private var showSubmissions = false
    
    var body: some View {
        List {
            // DR Forms Section
            Section {
                SettingsTile(
                    icon: "arrow.up.doc.fill",
                    iconColor: NupChatTheme.accent,
                    title: "My Submissions",
                    subtitle: "View submitted DR forms and sync status"
                ) {
                    showSubmissions = true
                }
            } header: {
                Text("DR FORMS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .sheet(isPresented: $showSubmissions) {
                NavigationView {
                    DRSubmissionView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showSubmissions = false
                                }
                            }
                        }
                }
            }
            
            // Account Section
            Section {
                SettingsTile(
                    icon: "person",
                    iconColor: Color(red: 0.008, green: 0.012, blue: 0.506),
                    title: "Profile",
                    subtitle: "Manage your nickname and identity"
                ) {
                    // Navigate to profile
                }
                
                SettingsTile(
                    icon: "key.fill",
                    iconColor: Color(red: 0.008, green: 0.012, blue: 0.506),
                    title: "Keys",
                    subtitle: "View and manage your Nostr keys"
                ) {
                    // Navigate to keys
                }
            } header: {
                Text("ACCOUNT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Network Section
            Section {
                SettingsTile(
                    icon: "antenna.radiowaves.left.and.right",
                    iconColor: Color.green,
                    title: "Bluetooth Mesh",
                    subtitle: "Configure local mesh networking"
                ) {
                    // Navigate to mesh settings
                }
                
                SettingsTile(
                    icon: "cloud",
                    iconColor: Color.purple,
                    title: "Nostr Relays",
                    subtitle: "Manage relay connections"
                ) {
                    // Navigate to relay settings
                }
            } header: {
                Text("NETWORK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // About Section
            Section {
                SettingsTile(
                    icon: "info.circle",
                    iconColor: .secondary,
                    title: "About NupChat",
                    subtitle: "Version 1.0.0"
                ) {
                    showAboutAlert = true
                }
                
                SettingsTile(
                    icon: "doc.text",
                    iconColor: .secondary,
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy"
                ) {
                    // Open privacy policy
                }
            } header: {
                Text("ABOUT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("About NupChat", isPresented: $showAboutAlert) {
            Button("Close", role: .cancel) {}
        } message: {
            Text("Decentralized P2P Messaging\n\nNupChat enables secure, decentralized communication using Bluetooth mesh networking and the Nostr protocol.\n\nVersion 1.0.0")
        }
    }
}

// MARK: - Settings Tile

struct SettingsTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
