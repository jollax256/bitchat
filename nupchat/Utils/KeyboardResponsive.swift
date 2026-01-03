//
// KeyboardResponsive.swift
// NupChat
//
// A simple modifier to handle keyboard avoidance when SwiftUI's default behavior fails
//

import SwiftUI
import Combine

#if os(iOS)
struct KeyboardResponsive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    private var bottomSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, max(0, keyboardHeight - bottomSafeArea))
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
    }
}

extension View {
    func keyboardResponsive() -> some View {
        modifier(KeyboardResponsive())
    }
}
#endif
