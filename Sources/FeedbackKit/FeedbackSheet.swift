import SwiftUI

public struct FeedbackSheet: View {
    private let appName: String
    private let onSubmit: (Feedback) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isMessageFocused: Bool
    @State private var category: FeedbackCategory = .feedback
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var isCompleted = false
    @State private var errorMessage: String?

    public init(
        appName: String,
        onSubmit: @escaping (Feedback) async throws -> Void
    ) {
        self.appName = appName
        self.onSubmit = onSubmit
    }

    public init(
        appName: String,
        onSubmit: @escaping (Feedback) -> Void
    ) {
        self.appName = appName
        self.onSubmit = { feedback in
            onSubmit(feedback)
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if isCompleted {
                    completedContent
                } else {
                    formContent
                }
            }
            .navigationTitle(Text("feedback.title", bundle: .module))
            .feedbackNavigationTitleDisplayMode()
            .toolbar {
                if isCompleted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text("feedback.close", bundle: .module)
                        }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Text("feedback.cancel", bundle: .module)
                        }
                        .disabled(isSubmitting)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            submit()
                        } label: {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("feedback.submit", bundle: .module)
                            }
                        }
                        .disabled(!canSubmit)
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            isMessageFocused = false
                        } label: {
                            Text("feedback.keyboard.done", bundle: .module)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isSubmitting)
    }

    private var formContent: some View {
        Form {
            Section {
                Text("feedback.description", bundle: .module)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker(selection: $category) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Text(category.localizedTitle)
                            .tag(category)
                    }
                } label: {
                    Text("feedback.category.title", bundle: .module)
                }
                .labelsHidden()
                .pickerStyle(.inline)
                .disabled(isSubmitting)
            } header: {
                Text("feedback.category.title", bundle: .module)
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("feedback.message.placeholder", bundle: .module)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .accessibilityHidden(true)
                    }

                    TextEditor(text: $message)
                        .focused($isMessageFocused)
                        .frame(minHeight: 180)
                        .disabled(isSubmitting)
                        .accessibilityLabel(Text("feedback.message.accessibilityLabel", bundle: .module))
                        .onChange(of: message) { _ in
                            if message.count > FeedbackValidation.maximumMessageLength {
                                message = FeedbackValidation.limitedMessage(message)
                            }
                            errorMessage = nil
                        }
                }
            } header: {
                Text("feedback.message.title", bundle: .module)
            } footer: {
                HStack(alignment: .firstTextBaseline) {
                    Text("feedback.message.requirement", bundle: .module)

                    Spacer(minLength: 12)

                    Text(verbatim: "\(message.count)/\(FeedbackValidation.maximumMessageLength)")
                        .monospacedDigit()
                        .foregroundStyle(isMessageLengthValid ? Color.secondary : Color.red)
                        .accessibilityLabel(characterCountAccessibilityLabel)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityLabel(errorAccessibilityLabel(errorMessage))
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var completedContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("feedback.completed.title", bundle: .module)
                .font(.title2)
                .fontWeight(.semibold)

            Text("feedback.completed.message", bundle: .module)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("feedback.close", bundle: .module)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    private var canSubmit: Bool {
        !isSubmitting && isMessageLengthValid
    }

    private var isMessageLengthValid: Bool {
        FeedbackValidation.isValidMessage(message)
    }

    private var trimmedMessage: String {
        FeedbackValidation.trimmedMessage(message)
    }

    private var characterCountAccessibilityLabel: Text {
        let format = NSLocalizedString(
            "feedback.characterCount %lld %lld",
            bundle: .module,
            comment: "Accessibility label for feedback character count"
        )
        return Text(String(format: format, message.count, FeedbackValidation.maximumMessageLength))
    }

    private func errorAccessibilityLabel(_ errorMessage: String) -> Text {
        let format = NSLocalizedString(
            "feedback.error.accessibilityLabel %@",
            bundle: .module,
            comment: "Accessibility label for feedback submission error"
        )
        return Text(String(format: format, errorMessage))
    }

    private func submit() {
        guard canSubmit else { return }

        isMessageFocused = false
        isSubmitting = true
        errorMessage = nil

        let feedback = Feedback(category: category, message: trimmedMessage)

        Task {
            do {
                try await onSubmit(feedback)
                isCompleted = true
            } catch {
                errorMessage = error.localizedDescription
            }

            isSubmitting = false
        }
    }
}

private extension View {
    @ViewBuilder
    func feedbackNavigationTitleDisplayMode() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
