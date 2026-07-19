#if os(iOS)
import SwiftUI

struct ShakeFeedbackPrompt: View {
    @Binding var isShakeEnabled: Bool
    let onReportProblem: () -> Void
    let onSendFeedback: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("feedback.shake.title", bundle: .module)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("feedback.shake.description", bundle: .module)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: onReportProblem) {
                    Text("feedback.shake.report", bundle: .module)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onSendFeedback) {
                    Text("feedback.shake.sendFeedback", bundle: .module)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Divider()

            Toggle(isOn: $isShakeEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("feedback.shake.toggle.title", bundle: .module)
                    Text("feedback.shake.toggle.subtitle", bundle: .module)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
#endif
