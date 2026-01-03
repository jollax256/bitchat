//
// MainNavigationShell.swift
// NupChat
//
// Main navigation shell with native TabView
// Contains Chat, DR Forms, and Settings tabs
//

import SwiftUI

struct MainNavigationShell: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.fill")
                }
                .tag(0)
            
            NavigationStack {
                DRFormView()
            }
            .tabItem {
                Label("DR", systemImage: "doc.text.fill")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView()
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .onChange(of: selectedTab) { _ in
            #if os(iOS)
            // Dismiss keyboard when switching tabs
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSettingsTab"))) { _ in
            withAnimation {
                selectedTab = 2
            }
        }
    }

}

// MARK: - Preview

#Preview {
    let keychain = PreviewKeychainManager()
    MainNavigationShell(
        viewModel: ChatViewModel(
            keychain: keychain,
            idBridge: NostrIdentityBridge(),
            identityManager: SecureIdentityStateManager(keychain)
        )
    )
}
