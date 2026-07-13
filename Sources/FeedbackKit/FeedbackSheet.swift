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
            .navigationTitle("feedback.title")
            .feedbackNavigationTitleDisplayMode()
            .toolbar {
                if isCompleted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("feedback.close") {
                            dismiss()
                        }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("feedback.cancel", role: .cancel) {
                            dismiss()
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
                                Text("feedback.submit")
                            }
                        }
                        .disabled(!canSubmit)
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("feedback.keyboard.done") {
                            isMessageFocused = false
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
                Text("feedback.description")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Section("feedback.category.title") {
                Picker("feedback.category.title", selection: $category) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Text(category.localizedTitle)
                            .tag(category)
                    }
                }
                .pickerStyle(.inline)
                .disabled(isSubmitting)
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("feedback.message.placeholder")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .accessibilityHidden(true)
                    }

                    TextEditor(text: $message)
                        .focused($isMessageFocused)
                        .frame(minHeight: 180)
                        .disabled(isSubmitting)
                        .accessibilityLabel(Text("feedback.message.accessibilityLabel"))
                        .onChange(of: message) { _ in
                            if message.count > Constants.maximumMessageLength {
                                message = String(message.prefix(Constants.maximumMessageLength))
                            }
                            errorMessage = nil
                        }
                }

                HStack {
                    Spacer()
                    Text("\(message.count)/\(Constants.maximumMessageLength)")
                        .font(.footnote)
                        .foregroundStyle(message.count > Constants.maximumMessageLength ? .red : .secondary)
                        .monospacedDigit()
                        .accessibilityLabel(Text("feedback.characterCount \(message.count) \(Constants.maximumMessageLength)"))
                }
            } header: {
                Text("feedback.message.title")
            } footer: {
                Text("feedback.message.requirement")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityLabel(Text("feedback.error.accessibilityLabel \(errorMessage)"))
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

            Text("feedback.completed.title")
                .font(.title2)
                .fontWeight(.semibold)

            Text("feedback.completed.message")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("feedback.close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    private var canSubmit: Bool {
        !isSubmitting
            && trimmedMessage.count >= Constants.minimumMessageLength
            && message.count <= Constants.maximumMessageLength
    }

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
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

private enum Constants {
    static let minimumMessageLength = 3
    static let maximumMessageLength = 2_000
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
