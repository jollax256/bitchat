//
// AppDrawer.swift
// NupChat
//
// Channel drawer with main networks, location channels, and settings access
//

import SwiftUI

struct AppDrawer: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var locationManager = LocationChannelManager.shared
    @EnvironmentObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    let onSettingsPressed: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            drawerHeader
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main Networks
                    sectionHeader("MAIN NETWORKS")
                    
                    channelTile(
                        name: "#mesh",
                        icon: "antenna.radiowaves.left.and.right",
                        isSelected: locationManager.selectedChannel.isMesh,
                        peerCount: meshPeerCount
                    ) {
                        locationManager.select(.mesh)
                        isPresented = false
                    }
                    
                    // Location Channels
                    sectionHeader("LOCATION CHANNELS")
                    
                    if locationManager.permissionState == .authorized {
                        if locationManager.availableChannels.isEmpty {
                            loadingRow
                        } else {
                            ForEach(locationManager.availableChannels) { channel in
                                channelTile(
                                    name: "#\(channel.geohash)",
                                    icon: "location",
                                    isSelected: isChannelSelected(channel),
                                    subtitle: channel.level.displayName
                                ) {
                                    locationManager.select(.location(channel))
                                    isPresented = false
                                }
                            }
                        }
                    } else {
                        locationPermissionButton
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 20)
            }
            .background(colorScheme == .dark ? Color.clear : Color(white: 0.98))
            
            // Footer with Settings
            settingsFooter
        }
        .background(colorScheme == .dark ? NupChatTheme.primaryBackground(colorScheme) : Color.white)
    }
    
    // MARK: - Header
    
    private var drawerHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("nuplogo")
                .resizable()
                .scaledToFit()
                .frame(height: 38)
            
            Text("NupChat")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
            
            Text("Secure P2P Mesh Network")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 24)
        .background(NupChatTheme.accent)
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .tracking(1.2)
            .padding(.horizontal, 12)
    }
    
    // MARK: - Channel Tile
    
    private func channelTile(
        name: String,
        icon: String,
        isSelected: Bool,
        subtitle: String? = nil,
        peerCount: Int = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? NupChatTheme.accent : .primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? NupChatTheme.accent : .primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if peerCount > 0 {
                    Text("\(peerCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSelected ? NupChatTheme.accent : Color(red: 0.008, green: 0.012, blue: 0.506))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? NupChatTheme.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Loading Row
    
    private var loadingRow: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading nearby channels...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Location Permission Button
    
    private var locationPermissionButton: some View {
        Button(action: {
            locationManager.enableLocationChannels()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "location")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Location")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text("Tap to enable location channels")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Settings Footer
    
    private var settingsFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.2)
            
            Button(action: {
                isPresented = false
                onSettingsPressed()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(NupChatTheme.accent)
                    
                    Text("Settings")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(NupChatTheme.accent)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(NupChatTheme.accent)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(NupChatTheme.accent.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
            .padding(16)
        }
    }
    
    // MARK: - Helpers
    
    private var meshPeerCount: Int {
        let myID = viewModel.meshService.myPeerID
        return viewModel.allPeers.reduce(0) { acc, peer in
            if peer.peerID != myID && (peer.isConnected || peer.isReachable) {
                return acc + 1
            }
            return acc
        }
    }
    
    private func isChannelSelected(_ channel: GeohashChannel) -> Bool {
        if case .location(let ch) = locationManager.selectedChannel {
            return ch == channel
        }
        return false
    }
}

// MARK: - Preview

#Preview {
    AppDrawer(isPresented: .constant(true)) {
        print("Settings pressed")
    }
    .environmentObject(
        ChatViewModel(
            keychain: PreviewKeychainManager(),
            idBridge: NostrIdentityBridge(),
            identityManager: SecureIdentityStateManager(PreviewKeychainManager())
        )
    )
}
