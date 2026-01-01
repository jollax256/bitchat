//
// MainNavigationShell.swift
// NupChat
//
// Main navigation shell with animated bottom navigation bar
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
        VStack(spacing: 0) {
            // Tab content
            TabView(selection: $selectedTab) {
                ContentView()
                    .environmentObject(viewModel)
                    .tag(0)
                
                NavigationStack {
                    DRFormView()
                }
                .tag(1)
                
                NavigationStack {
                    SettingsView()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSettingsTab"))) { _ in
                withAnimation {
                    selectedTab = 2
                }
            }
            
            // Custom bottom navigation bar
            BottomNavigationBar(selectedTab: $selectedTab, colorScheme: colorScheme)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    let colorScheme: ColorScheme
    
    private let items: [(icon: String, activeIcon: String, label: String)] = [
        ("bubble.left", "bubble.left.fill", "Chat"),
        ("doc.text", "doc.text.fill", "DR"),
        ("gearshape", "gearshape.fill", "Settings")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.2)
            
            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    BottomNavItem(
                        icon: selectedTab == index ? items[index].activeIcon : items[index].icon,
                        label: items[index].label,
                        isSelected: selectedTab == index,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = index
                        }
                        #if os(iOS)
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        #endif
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(NupChatTheme.primaryBackground(colorScheme))
        }
    }
}

// MARK: - Bottom Nav Item

struct BottomNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    private var itemColor: Color {
        if isSelected {
            return NupChatTheme.accent
        }
        return colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(itemColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? NupChatTheme.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
