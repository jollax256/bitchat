//
// Theme.swift
// bitchat
//
// Modern theme system for Bitchat iOS app
// This is free and unencumbered software released into the public domain.
//

import SwiftUI

// MARK: - BitchatTheme

/// Centralized theme system providing modern colors, gradients, and shadows
/// for the Bitchat chat interface.
enum BitchatTheme {
    
    // MARK: - Primary Colors
    
    /// Primary accent color - used for interactive elements and highlights
    static var accent: Color {
        Color.red
    }
    
    /// Secondary accent for alternative actions
    static var secondaryAccent: Color {
        Color.purple
    }
    
    // MARK: - Background Colors
    
    /// Primary background color (adaptive to color scheme)
    static func primaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    /// Secondary background for cards, input fields, etc.
    static func secondaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.12) 
            : Color(UIColor.systemGray6)
    }
    
    /// Tertiary background for nested elements
    static func tertiaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.18) 
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
    
    /// Outgoing message bubble gradient
    static var outgoingBubbleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.9, green: 0.2, blue: 0.2),
                Color(red: 0.75, green: 0.15, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Outgoing message bubble solid color (for simpler use)
    static var outgoingBubble: Color {
        Color(red: 0.9, green: 0.2, blue: 0.2)
    }
    
    /// Incoming message bubble background
    static func incomingBubble(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.20) 
            : Color(UIColor.systemGray5)
    }
    
    /// System message background
    static func systemMessageBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.15).opacity(0.8) 
            : Color(UIColor.systemGray6).opacity(0.8)
    }
    
    // MARK: - Status Colors
    
    /// Online/connected status
    static var statusOnline: Color {
        Color.green
    }
    
    /// Away/idle status
    static var statusAway: Color {
        Color.orange
    }
    
    /// Offline status
    static var statusOffline: Color {
        Color.gray
    }
    
    /// Read receipt color
    static var readReceipt: Color {
        Color.red
    }
    
    /// Delivered indicator color
    static func deliveredIndicator(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(UIColor.secondaryLabel)
    }
    
    // MARK: - Semantic Colors
    
    /// Mesh channel color
    static var meshChannel: Color {
        Color(hue: 0.60, saturation: 0.85, brightness: 0.82)
    }
    
    /// Geohash/location channel color
    static var geoChannel: Color {
        Color.green
    }
    
    /// Private chat accent
    static var privateChat: Color {
        Color.orange
    }
    
    /// Error/warning color
    static var error: Color {
        Color.red
    }
    
    // MARK: - Divider
    
    static func divider(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.25) 
            : Color(UIColor.separator)
    }
}

// MARK: - Gradients

extension BitchatTheme {
    
    /// Header gradient for navigation areas
    static func headerGradient(_ colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark
            ? LinearGradient(
                colors: [Color.black.opacity(0.95), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
    }
    
    /// Subtle accent gradient for buttons
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.red,
                Color.red.opacity(0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Shadows

extension BitchatTheme {
    
    /// Standard card/bubble shadow
    static func cardShadow(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        colorScheme == .dark
            ? (Color.black.opacity(0.4), 8, 0, 4)
            : (Color.black.opacity(0.08), 8, 0, 4)
    }
    
    /// Subtle shadow for floating elements
    static func subtleShadow(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        colorScheme == .dark
            ? (Color.black.opacity(0.3), 4, 0, 2)
            : (Color.black.opacity(0.05), 4, 0, 2)
    }
    
    /// Input field shadow
    static func inputShadow(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        colorScheme == .dark
            ? (Color.black.opacity(0.35), 6, 0, 2)
            : (Color.black.opacity(0.06), 6, 0, 2)
    }
}

// MARK: - Corner Radii

extension BitchatTheme {
    
    /// Message bubble corner radius
    static let bubbleCornerRadius: CGFloat = 18
    
    /// Large corner radius for cards
    static let cardCornerRadius: CGFloat = 16
    
    /// Medium corner radius for buttons
    static let buttonCornerRadius: CGFloat = 12
    
    /// Small corner radius for chips/tags
    static let chipCornerRadius: CGFloat = 8
    
    /// Input field corner radius
    static let inputCornerRadius: CGFloat = 20
}

// MARK: - Spacing

extension BitchatTheme {
    
    /// Space between message bubbles from same sender
    static let messageSameAuthorSpacing: CGFloat = 2
    
    /// Space between message bubbles from different senders
    static let messageDifferentAuthorSpacing: CGFloat = 12
    
    /// Horizontal padding for message bubbles
    static let bubbleHorizontalPadding: CGFloat = 12
    
    /// Vertical padding for message bubbles
    static let bubbleVerticalPadding: CGFloat = 8
    
    /// Maximum width ratio for message bubbles (relative to screen)
    static let bubbleMaxWidthRatio: CGFloat = 0.75
}

// MARK: - Animation

extension BitchatTheme {
    
    /// Standard animation duration
    static let animationDuration: Double = 0.25
    
    /// Fast animation duration
    static let animationFast: Double = 0.15
    
    /// Slow animation duration
    static let animationSlow: Double = 0.35
    
    /// Spring animation for bouncy effects
    static var springAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard card shadow from theme
    func cardShadow(colorScheme: ColorScheme) -> some View {
        let shadow = BitchatTheme.cardShadow(colorScheme)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply subtle shadow from theme
    func subtleShadow(colorScheme: ColorScheme) -> some View {
        let shadow = BitchatTheme.subtleShadow(colorScheme)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply input field shadow from theme
    func inputShadow(colorScheme: ColorScheme) -> some View {
        let shadow = BitchatTheme.inputShadow(colorScheme)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
