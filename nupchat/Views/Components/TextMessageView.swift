//
// TextMessageView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct TextMessageView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @EnvironmentObject private var viewModel: ChatViewModel
    
    let message: BitchatMessage
    let isOutgoing: Bool
    @Binding var expandedMessageIDs: Set<String>
    
    init(message: BitchatMessage, isOutgoing: Bool = false, expandedMessageIDs: Binding<Set<String>>) {
        self.message = message
        self.isOutgoing = isOutgoing
        self._expandedMessageIDs = expandedMessageIDs
    }
    
    private var bubbleBackground: some View {
        let corners: UIRectCorner = isOutgoing 
            ? [.topLeft, .topRight, .bottomLeft] 
            : [.topLeft, .topRight, .bottomRight]
        
        return ChatBubbleShape(corners: corners, radius: 18)
            .fill(isOutgoing ? AnyShapeStyle(NupChatTheme.outgoingBubbleGradient) : AnyShapeStyle(NupChatTheme.incomingBubble(colorScheme)))
    }
    
    private var textColor: Color {
        isOutgoing ? .white : NupChatTheme.primaryText(colorScheme)
    }
    
    private var secondaryTextColor: Color {
        isOutgoing ? .white.opacity(0.7) : NupChatTheme.secondaryText(colorScheme)
    }
    
    var body: some View {
        let cashuLinks = message.content.extractCashuLinks()
        let lightningLinks = message.content.extractLightningLinks()
        let isLong = (message.content.count > TransportConfig.uiLongMessageLengthThreshold || message.content.hasVeryLongToken(threshold: TransportConfig.uiVeryLongTokenThreshold)) && cashuLinks.isEmpty
        let isExpanded = expandedMessageIDs.contains(message.id)
        
        HStack {
            if isOutgoing { Spacer(minLength: 60) }
            
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
                // Message bubble
                VStack(alignment: .leading, spacing: 2) {
                    // Sender name for group chats
                    if !isOutgoing && !message.isPrivate {
                        Text(message.sender)
                            .font(.bitchatSystem(size: 12, weight: .bold))
                            .foregroundColor(NupChatTheme.accent)
                            .padding(.bottom, 1)
                    }
                    
                    // Message content
                    Text(viewModel.formatMessageAsText(message, colorScheme: colorScheme))
                        .font(.bitchatSystem(size: 15))
                        .foregroundColor(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(isLong && !isExpanded ? TransportConfig.uiLongMessageLineLimit : nil)
                    
                    // Expand/Collapse for very long messages
                    if isLong {
                        Button(action: {
                            if isExpanded { expandedMessageIDs.remove(message.id) }
                            else { expandedMessageIDs.insert(message.id) }
                        }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.bitchatSystem(size: 12, weight: .medium))
                                .foregroundColor(isOutgoing ? .white.opacity(0.8) : NupChatTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Bottom row: timestamp + delivery status
                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.bitchatMono(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        // Delivery status indicator for private messages
                        if message.isPrivate && message.sender == viewModel.nickname,
                           let status = message.deliveryStatus {
                            DeliveryStatusView(status: status, isOutgoing: isOutgoing)
                        }
                    }
                }
                .padding(.horizontal, NupChatTheme.bubbleHorizontalPadding)
                .padding(.vertical, NupChatTheme.bubbleVerticalPadding)
                .background(bubbleBackground)
                .subtleShadow(colorScheme: colorScheme)
                
                // Payment chips (outside bubble for better visibility)
                if !lightningLinks.isEmpty || !cashuLinks.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(lightningLinks, id: \.self) { link in
                            PaymentChipView(paymentType: .lightning(link))
                        }
                        ForEach(cashuLinks, id: \.self) { link in
                            PaymentChipView(paymentType: .cashu(link))
                        }
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * NupChatTheme.bubbleMaxWidthRatio, alignment: isOutgoing ? .trailing : .leading)
            
            if !isOutgoing { Spacer(minLength: 60) }
        }
    }
}

struct ChatBubbleShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

@available(macOS 14, iOS 17, *)
#Preview {
    @Previewable @State var ids: Set<String> = []
    let keychain = PreviewKeychainManager()
    
    ScrollView {
        VStack(spacing: 8) {
            TextMessageView(message: .preview, isOutgoing: false, expandedMessageIDs: $ids)
            TextMessageView(message: .preview, isOutgoing: true, expandedMessageIDs: $ids)
        }
        .padding()
    }
    .background(Color.black)
    .environment(\.colorScheme, .dark)
    .environmentObject(
        ChatViewModel(
            keychain: keychain,
            idBridge: NostrIdentityBridge(),
            identityManager: SecureIdentityStateManager(keychain)
        )
    )
}
