import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        BitchatTheme.primaryBackground(colorScheme)
    }
    
    private var textColor: Color {
        BitchatTheme.primaryText(colorScheme)
    }
    
    private var secondaryTextColor: Color {
        BitchatTheme.secondaryText(colorScheme)
    }
    
    private var accentColor: Color {
        BitchatTheme.accent
    }
    
    // MARK: - Constants
    private enum Strings {
        static let appName: LocalizedStringKey = "app_info.app_name"
        static let tagline: LocalizedStringKey = "app_info.tagline"

        enum Features {
            static let title: LocalizedStringKey = "app_info.features.title"
            static let offlineComm = AppInfoFeatureInfo(
                icon: "wifi.slash",
                title: "app_info.features.offline.title",
                description: "app_info.features.offline.description"
            )
            static let encryption = AppInfoFeatureInfo(
                icon: "lock.shield",
                title: "app_info.features.encryption.title",
                description: "app_info.features.encryption.description"
            )
            static let extendedRange = AppInfoFeatureInfo(
                icon: "antenna.radiowaves.left.and.right",
                title: "app_info.features.extended_range.title",
                description: "app_info.features.extended_range.description"
            )
            static let mentions = AppInfoFeatureInfo(
                icon: "at",
                title: "app_info.features.mentions.title",
                description: "app_info.features.mentions.description"
            )
            static let favorites = AppInfoFeatureInfo(
                icon: "star.fill",
                title: "app_info.features.favorites.title",
                description: "app_info.features.favorites.description"
            )
            static let geohash = AppInfoFeatureInfo(
                icon: "number",
                title: "app_info.features.geohash.title",
                description: "app_info.features.geohash.description"
            )
        }

        enum Privacy {
            static let title: LocalizedStringKey = "app_info.privacy.title"
            static let noTracking = AppInfoFeatureInfo(
                icon: "eye.slash",
                title: "app_info.privacy.no_tracking.title",
                description: "app_info.privacy.no_tracking.description"
            )
            static let ephemeral = AppInfoFeatureInfo(
                icon: "shuffle",
                title: "app_info.privacy.ephemeral.title",
                description: "app_info.privacy.ephemeral.description"
            )
            static let panic = AppInfoFeatureInfo(
                icon: "hand.raised.fill",
                title: "app_info.privacy.panic.title",
                description: "app_info.privacy.panic.description"
            )
        }

        enum HowToUse {
            static let title: LocalizedStringKey = "app_info.how_to_use.title"
            static let instructions: [LocalizedStringKey] = [
                "app_info.how_to_use.set_nickname",
                "app_info.how_to_use.change_channels",
                "app_info.how_to_use.open_sidebar",
                "app_info.how_to_use.start_dm",
                "app_info.how_to_use.clear_chat",
                "app_info.how_to_use.commands"
            ]
        }

        enum Warning {
            static let title: LocalizedStringKey = "app_info.warning.title"
            static let message: LocalizedStringKey = "app_info.warning.message"
        }
    }
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            // Custom header for macOS
            HStack {
                Spacer()
                Button("app_info.done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(accentColor)
                .padding()
            }
            .background(backgroundColor.opacity(0.95))
            
            ScrollView {
                infoContent
            }
            .background(backgroundColor)
        }
        .frame(width: 600, height: 700)
        #else
        NavigationView {
            ScrollView {
                infoContent
            }
            .background(backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(BitchatTheme.secondaryText(colorScheme))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("app_info.close")
                }
            }
        }
        #endif
    }
    
    @ViewBuilder
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with gradient
            VStack(alignment: .center, spacing: 12) {
                // App icon or logo area
                ZStack {
                    Circle()
                        .fill(BitchatTheme.accentGradient)
                        .frame(width: 80, height: 80)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                .cardShadow(colorScheme: colorScheme)
                
                Text(Strings.appName)
                    .font(.bitchatSystem(size: 28, weight: .bold))
                    .foregroundColor(textColor)
                
                Text(Strings.tagline)
                    .font(.bitchatSystem(size: 15))
                    .foregroundColor(secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            
            // How to Use - Card style
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(Strings.HowToUse.title)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(Strings.HowToUse.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.bitchatSystem(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(accentColor))
                            Text(instruction)
                                .font(.bitchatSystem(size: 14))
                                .foregroundColor(textColor)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: BitchatTheme.cardCornerRadius, style: .continuous)
                        .fill(BitchatTheme.secondaryBackground(colorScheme))
                )
            }

            // Features - Card style
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(Strings.Features.title)

                VStack(spacing: 16) {
                    FeatureRow(info: Strings.Features.offlineComm)
                    FeatureRow(info: Strings.Features.encryption)
                    FeatureRow(info: Strings.Features.extendedRange)
                    FeatureRow(info: Strings.Features.favorites)
                    FeatureRow(info: Strings.Features.geohash)
                    FeatureRow(info: Strings.Features.mentions)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: BitchatTheme.cardCornerRadius, style: .continuous)
                        .fill(BitchatTheme.secondaryBackground(colorScheme))
                )
            }

            // Privacy - Card style
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(Strings.Privacy.title)

                VStack(spacing: 16) {
                    FeatureRow(info: Strings.Privacy.noTracking)
                    FeatureRow(info: Strings.Privacy.ephemeral)
                    FeatureRow(info: Strings.Privacy.panic)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: BitchatTheme.cardCornerRadius, style: .continuous)
                        .fill(BitchatTheme.secondaryBackground(colorScheme))
                )
            }

            // Warning - Alert style card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(BitchatTheme.error)
                    Text(Strings.Warning.title)
                        .font(.bitchatSystem(size: 14, weight: .bold))
                        .foregroundColor(BitchatTheme.error)
                }
                
                Text(Strings.Warning.message)
                    .font(.bitchatSystem(size: 13))
                    .foregroundColor(BitchatTheme.error.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: BitchatTheme.cardCornerRadius, style: .continuous)
                    .fill(BitchatTheme.error.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: BitchatTheme.cardCornerRadius, style: .continuous)
                    .stroke(BitchatTheme.error.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
    }
}

struct AppInfoFeatureInfo {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

struct SectionHeader: View {
    let title: LocalizedStringKey
    @Environment(\.colorScheme) var colorScheme
    
    init(_ title: LocalizedStringKey) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.bitchatSystem(size: 18, weight: .bold))
            .foregroundColor(BitchatTheme.primaryText(colorScheme))
    }
}

struct FeatureRow: View {
    let info: AppInfoFeatureInfo
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: info.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(BitchatTheme.accent)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(info.title)
                    .font(.bitchatSystem(size: 15, weight: .semibold))
                    .foregroundColor(BitchatTheme.primaryText(colorScheme))
                
                Text(info.description)
                    .font(.bitchatSystem(size: 13))
                    .foregroundColor(BitchatTheme.secondaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview("Default") {
    AppInfoView()
}

#Preview("Dynamic Type XXL") {
    AppInfoView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Dynamic Type XS") {
    AppInfoView()
        .environment(\.sizeCategory, .extraSmall)
}
