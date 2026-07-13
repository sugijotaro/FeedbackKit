import SwiftUI

public enum FeedbackCategory: String, CaseIterable, Sendable {
    case bug
    case featureRequest
    case feedback
    case other

    public var localizedTitle: String {
        switch self {
        case .bug:
            String(localized: "feedback.category.bug", bundle: .module)
        case .featureRequest:
            String(localized: "feedback.category.featureRequest", bundle: .module)
        case .feedback:
            String(localized: "feedback.category.feedback", bundle: .module)
        case .other:
            String(localized: "feedback.category.other", bundle: .module)
        }
    }
}

public struct Feedback: Sendable {
    public let category: FeedbackCategory
    public let message: String

    public init(category: FeedbackCategory, message: String) {
        self.category = category
        self.message = message
    }
}
