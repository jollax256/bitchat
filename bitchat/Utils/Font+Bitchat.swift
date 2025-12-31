import SwiftUI

/// Provides Dynamic Type aware font helpers that map existing fixed sizes onto
/// preferred text styles so the UI scales with user accessibility settings.
/// 
/// Modern design uses `.rounded` by default for a friendly, approachable feel.
/// Use `.monospaced` for timestamps, code, or technical elements.
extension Font {
    /// Modern system font with rounded design by default
    /// - Parameters:
    ///   - size: Base font size (will be mapped to text style for Dynamic Type)
    ///   - weight: Font weight (default: .regular)
    ///   - design: Font design (default: .rounded for modern look)
    /// - Returns: A font configured for the given parameters
    static func bitchatSystem(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .rounded) -> Font {
        let style = Font.TextStyle.bitchatPreferredStyle(for: size)
        var font = Font.system(style, design: design)
        if weight != .regular {
            font = font.weight(weight)
        }
        return font
    }
    
    /// Monospaced font for technical content (timestamps, codes, etc.)
    static func bitchatMono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return bitchatSystem(size: size, weight: weight, design: .monospaced)
    }
}

private extension Font.TextStyle {
    static func bitchatPreferredStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11.5:
            return .caption2
        case ..<13.0:
            return .caption
        case ..<13.75:
            return .footnote
        case ..<15.5:
            return .subheadline
        case ..<17.5:
            return .callout
        case ..<19.5:
            return .body
        case ..<22.5:
            return .title3
        case ..<27.5:
            return .title2
        case ..<34.0:
            return .title
        default:
            return .largeTitle
        }
    }
}
