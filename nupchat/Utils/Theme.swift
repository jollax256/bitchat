//
// Theme.swift
// NupChat
//
// Modern theme system for NupChat iOS app
// This is free and unencumbered software released into the public domain.
//

import SwiftUI

// MARK: - NupChatTheme

/// Centralized theme system providing modern colors, gradients, and shadows
/// for the NupChat chat interface.
enum NupChatTheme {
    
    // MARK: - Primary Colors
    
    /// Primary accent color - NUP Red
    static var accent: Color {
        Color(red: 0.894, green: 0.114, blue: 0.188) // #E41D30
    }
    
    /// Secondary accent - Navy Blue
    static var secondaryAccent: Color {
        Color(red: 0.008, green: 0.012, blue: 0.506) // #020381
    }
    
    // MARK: - Background Colors
    
    /// Primary background color (adaptive to color scheme)
    static func primaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 0.145, green: 0.149, blue: 0.220) // #252638 Ebony Clay
            : Color.white
    }
    
    /// Secondary background for cards, input fields, etc.
    static func secondaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
            : Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    }
    
    /// Tertiary background for nested elements
    static func tertiaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.16) 
            : Color(UIColor.systemGray5)
    }
    
    // MARK: - Text Colors
    
    /// Primary text color
    static func primaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    /// Secondary text for subtitles, timestamps
    static func secondaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.6) 
            : Color(UIColor.secondaryLabel)
    }
    
    /// Tertiary text for hints, placeholders
    static func tertiaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.4) 
            : Color(UIColor.tertiaryLabel)
    }
    
    // MARK: - Message Bubble Colors
    
    /// Outgoing message bubble gradient - NUP Red
    static var outgoingBubbleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.894, green: 0.114, blue: 0.188), // #E41D30
                Color(red: 0.75, green: 0.1, blue: 0.15)      // Darker red
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Outgoing message bubble solid color (for simpler use)
    static var outgoingBubble: Color {
        Color(red: 0.894, green: 0.114, blue: 0.188) // #E41D30
    }
    
    /// Incoming message bubble background
    static func incomingBubble(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 0.12, green: 0.17, blue: 0.20) // #1F2C34 WhatsApp Dark
            : Color.white
    }
    
    /// System message background
    static func systemMessageBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.14).opacity(0.85) 
            : Color(UIColor.systemGray6).opacity(0.85)
    }
    
    // MARK: - Status Colors
    
    /// Online/connected status
    static var statusOnline: Color {
        Color(red: 0.22, green: 0.78, blue: 0.44) // #38C76F softer green
    }
    
    /// Away/idle status
    static var statusAway: Color {
        Color(red: 0.96, green: 0.65, blue: 0.14) // #F5A623 warm amber
    }
    
    /// Offline status
    static var statusOffline: Color {
        Color.gray
    }
    
    /// Read receipt color
    static var readReceipt: Color {
        Color(red: 0.545, green: 0.361, blue: 0.965) // Match accent
    }
    
    /// Delivered indicator color
    static func deliveredIndicator(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(UIColor.secondaryLabel)
    }
    
    // MARK: - Semantic Colors
    
    /// Mesh channel color
    static var meshChannel: Color {
        Color(red: 0.545, green: 0.361, blue: 0.965) // Purple accent
    }
    
    /// Geohash/location channel color
    static var geoChannel: Color {
        Color(red: 0.894, green: 0.114, blue: 0.188) // Red
    }
    
    /// Private chat accent
    static var privateChat: Color {
        Color(red: 0.96, green: 0.65, blue: 0.14) // Amber
    }
    
    /// Error/warning color
    static var error: Color {
        Color(red: 0.94, green: 0.27, blue: 0.33) // #F04555
    }
    
    // MARK: - Divider
    
    static func divider(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.22) 
            : Color(UIColor.separator)
    }
}

// MARK: - Gradients

extension NupChatTheme {
    
    /// Header gradient for navigation areas
    static func headerGradient(_ colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark
            ? LinearGradient(
                colors: [Color.black.opacity(0.98), Color.black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [Color.white.opacity(0.98), Color.white.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
    }
    
    /// Accent gradient for buttons and highlights
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.894, green: 0.114, blue: 0.188), // #E41D30
                Color(red: 0.75, green: 0.1, blue: 0.15)      // Darker red
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Shadows

extension NupChatTheme {
    
    /// Standard card/bubble shadow - more pronounced for depth
    static func cardShadow(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        colorScheme == .dark
            ? (Color.black.opacity(0.5), 12, 0, 6)
            : (Color.black.opacity(0.10), 12, 0, 6)
    }
    
    /// Subtle shadow for floating elements
    static func subtleShadow(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        colorScheme == .dark
            ? (Color.black.opacity(0.35), 6, 0, 3)
            : (Color.black.opacity(0.06), 6, 0, 3)
    }
    
    /// Input field shadow
    static func inputShadow(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        colorScheme == .dark
            ? (Color.black.opacity(0.4), 8, 0, 3)
            : (Color.black.opacity(0.07), 8, 0, 3)
    }
}

// MARK: - Corner Radii

extension NupChatTheme {
    
    /// Message bubble corner radius
    static let bubbleCornerRadius: CGFloat = 20
    
    /// Large corner radius for cards
    static let cardCornerRadius: CGFloat = 18
    
    /// Medium corner radius for buttons
    static let buttonCornerRadius: CGFloat = 12
    
    /// Small corner radius for chips/tags
    static let chipCornerRadius: CGFloat = 8
    
    /// Input field corner radius
    static let inputCornerRadius: CGFloat = 24
}

// MARK: - Spacing

extension NupChatTheme {
    
    /// Space between message bubbles from same sender
    static let messageSameAuthorSpacing: CGFloat = 2
    
    /// Space between message bubbles from different senders
    static let messageDifferentAuthorSpacing: CGFloat = 14
    
    /// Horizontal padding for message bubbles
    static let bubbleHorizontalPadding: CGFloat = 14
    
    /// Vertical padding for message bubbles
    static let bubbleVerticalPadding: CGFloat = 10
    
    /// Maximum width ratio for message bubbles (relative to screen)
    static let bubbleMaxWidthRatio: CGFloat = 0.75
}

// MARK: - Animation

extension NupChatTheme {
    
    /// Standard animation duration
    static let animationDuration: Double = 0.25
    
    /// Fast animation duration
    static let animationFast: Double = 0.15
    
    /// Slow animation duration
    static let animationSlow: Double = 0.35
    
    /// Spring animation for bouncy effects
    static var springAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.72)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard card shadow from theme
    func cardShadow(colorScheme: ColorScheme) -> some View {
        let shadow = NupChatTheme.cardShadow(colorScheme)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply subtle shadow from theme
    func subtleShadow(colorScheme: ColorScheme) -> some View {
        let shadow = NupChatTheme.subtleShadow(colorScheme)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply input field shadow from theme
    func inputShadow(colorScheme: ColorScheme) -> some View {
        let shadow = NupChatTheme.inputShadow(colorScheme)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
