//
// PaymentChipView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct PaymentChipView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    enum PaymentType {
        case cashu(String)
        case lightning(String)
        
        var url: URL? {
            switch self {
            case .cashu(let link), .lightning(let link):
                return URL(string: link)
            }
        }
        
        var emoji: String {
            switch self {
            case .cashu:        "🥜"
            case .lightning:    "⚡"
            }
        }
        
        var label: String {
            switch self {
            case .cashu:
                String(localized: "content.payment.cashu", comment: "Label for Cashu payment chip")
            case .lightning:
                String(localized: "content.payment.lightning", comment: "Label for Lightning payment chip")
            }
        }
        
        var accentColor: Color {
            switch self {
            case .cashu:
                Color.orange
            case .lightning:
                Color.yellow
            }
        }
    }
    
    let paymentType: PaymentType
    
    private var backgroundColor: Color {
        colorScheme == .dark 
            ? paymentType.accentColor.opacity(0.15)
            : paymentType.accentColor.opacity(0.12)
    }
    
    private var borderColor: Color {
        paymentType.accentColor.opacity(0.3)
    }
    
    private var textColor: Color {
        colorScheme == .dark 
            ? paymentType.accentColor
            : paymentType.accentColor.opacity(0.9)
    }
    
    var body: some View {
        Button {
            #if os(iOS)
            if let url = paymentType.url { openURL(url) }
            #else
            if let url = paymentType.url { NSWorkspace.shared.open(url) }
            #endif
        } label: {
            HStack(spacing: 6) {
                Text(paymentType.emoji)
                    .font(.system(size: 14))
                Text(paymentType.label)
                    .font(.bitchatSystem(size: 12, weight: .semibold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .foregroundColor(textColor)
        }
        .buttonStyle(.plain)
        .subtleShadow(colorScheme: colorScheme)
    }
}

#Preview {
    let cashuLink = "https://example.com/cashu"
    let lightningLink = "https://example.com/lightning"
    
    VStack(spacing: 20) {
        Text("Light Mode")
            .font(.headline)
        HStack {
            PaymentChipView(paymentType: .cashu(cashuLink))
            PaymentChipView(paymentType: .lightning(lightningLink))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .environment(\.colorScheme, .light)
        
        Text("Dark Mode")
            .font(.headline)
        HStack {
            PaymentChipView(paymentType: .cashu(cashuLink))
            PaymentChipView(paymentType: .lightning(lightningLink))
        }
        .padding()
        .background(Color.black)
        .cornerRadius(12)
        .environment(\.colorScheme, .dark)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
