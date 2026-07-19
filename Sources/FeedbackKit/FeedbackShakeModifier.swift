#if os(iOS)
import SwiftUI

public extension View {
    func feedbackSheetOnShake(
        isEnabled: Binding<Bool>,
        onSubmit: @escaping (Feedback) async throws -> Void,
        onWriteAppStoreReview: ((Feedback) -> Void)? = nil
    ) -> some View {
        modifier(
            FeedbackShakeModifier(
                isEnabled: isEnabled,
                onSubmit: onSubmit,
                onWriteAppStoreReview: onWriteAppStoreReview
            )
        )
    }

    func feedbackSheetOnShake(
        isEnabled: Binding<Bool>,
        onSubmit: @escaping (Feedback) -> Void,
        onWriteAppStoreReview: ((Feedback) -> Void)? = nil
    ) -> some View {
        modifier(
            FeedbackShakeModifier(
                isEnabled: isEnabled,
                onSubmit: { feedback in
                    onSubmit(feedback)
                },
                onWriteAppStoreReview: onWriteAppStoreReview
            )
        )
    }
}

private struct FeedbackShakeModifier: ViewModifier {
    @Binding var isEnabled: Bool
    let onSubmit: (Feedback) async throws -> Void
    let onWriteAppStoreReview: ((Feedback) -> Void)?

    @State private var isPromptPresented = false
    @State private var isFeedbackPresented = false
    @State private var shouldPresentFeedback = false
    @State private var initialCategory: FeedbackCategory = .feedback

    func body(content: Content) -> some View {
        content
            .background {
                ShakeGestureDetector(isEnabled: isEnabled, onShake: presentPrompt)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
            .sheet(isPresented: $isPromptPresented, onDismiss: promptDidDismiss) {
                ShakeFeedbackPrompt(
                    isShakeEnabled: $isEnabled,
                    onReportProblem: requestProblemReport,
                    onSendFeedback: requestGeneralFeedback
                )
            }
            .sheet(isPresented: $isFeedbackPresented) {
                FeedbackSheet(
                    initialCategory: initialCategory,
                    onSubmit: onSubmit,
                    onWriteAppStoreReview: onWriteAppStoreReview
                )
            }
    }

    private func presentPrompt() {
        guard isEnabled, !isPromptPresented, !isFeedbackPresented else { return }
        isPromptPresented = true
    }

    private func requestProblemReport() {
        requestFeedbackForm(initialCategory: .bug)
    }

    private func requestGeneralFeedback() {
        requestFeedbackForm(initialCategory: .feedback)
    }

    private func requestFeedbackForm(initialCategory: FeedbackCategory) {
        self.initialCategory = initialCategory
        shouldPresentFeedback = true
        isPromptPresented = false
    }

    private func promptDidDismiss() {
        guard shouldPresentFeedback else { return }
        shouldPresentFeedback = false
        isFeedbackPresented = true
    }
}
#endif
