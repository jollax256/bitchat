//
// DeliveryStatusView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct DeliveryStatusView: View {
    @Environment(\.colorScheme) private var colorScheme
    let status: DeliveryStatus
    var isOutgoing: Bool = false

    // MARK: - Computed Properties
    
    private var iconColor: Color {
        switch status {
        case .sending, .sent:
            return isOutgoing ? .white.opacity(0.6) : BitchatTheme.secondaryText(colorScheme)
        case .delivered:
            return isOutgoing ? .white.opacity(0.8) : BitchatTheme.deliveredIndicator(colorScheme)
        case .read:
            return BitchatTheme.readReceipt
        case .failed:
            return BitchatTheme.error
        case .partiallyDelivered:
            return isOutgoing ? .white.opacity(0.6) : BitchatTheme.secondaryText(colorScheme)
        }
    }

    private enum Strings {
        static func delivered(to nickname: String) -> String {
            String(
                format: String(localized: "content.delivery.delivered_to", comment: "Tooltip for delivered private messages"),
                locale: .current,
                nickname
            )
        }

        static func read(by nickname: String) -> String {
            String(
                format: String(localized: "content.delivery.read_by", comment: "Tooltip for read private messages"),
                locale: .current,
                nickname
            )
        }

        static func failed(_ reason: String) -> String {
            String(
                format: String(localized: "content.delivery.failed", comment: "Tooltip for failed message delivery"),
                locale: .current,
                reason
            )
        }

        static func deliveredToMembers(_ reached: Int, _ total: Int) -> String {
            String(
                format: String(localized: "content.delivery.delivered_members", comment: "Tooltip for partially delivered messages"),
                locale: .current,
                reached,
                total
            )
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        switch status {
        case .sending:
            Image(systemName: "circle")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(iconColor)
            
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(iconColor)
            
        case .delivered(let nickname, _):
            HStack(spacing: -3) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(iconColor)
            .help(Strings.delivered(to: nickname))
            
        case .read(let nickname, _):
            HStack(spacing: -3) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(iconColor)
            .help(Strings.read(by: nickname))
            
        case .failed(let reason):
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(iconColor)
                .help(Strings.failed(reason))
            
        case .partiallyDelivered(let reached, let total):
            HStack(spacing: 2) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .medium))
                Text(verbatim: "\(reached)/\(total)")
                    .font(.bitchatMono(size: 9))
            }
            .foregroundColor(iconColor)
            .help(Strings.deliveredToMembers(reached, total))
        }
    }
}

#Preview {
    let statuses: [DeliveryStatus] = [
        .sending,
        .sent,
        .delivered(to: "John Doe", at: Date()),
        .read(by: "Jane Doe", at: Date()),
        .failed(reason: "Offline"),
        .partiallyDelivered(reached: 2, total: 5)
    ]
    
    VStack(spacing: 16) {
        Text("Outgoing (white)")
            .font(.headline)
        HStack(spacing: 16) {
            ForEach(statuses, id: \.self) { status in
                DeliveryStatusView(status: status, isOutgoing: true)
            }
        }
        .padding()
        .background(BitchatTheme.outgoingBubble)
        .cornerRadius(12)
        
        Text("Incoming (themed)")
            .font(.headline)
        HStack(spacing: 16) {
            ForEach(statuses, id: \.self) { status in
                DeliveryStatusView(status: status, isOutgoing: false)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    .padding()
}
