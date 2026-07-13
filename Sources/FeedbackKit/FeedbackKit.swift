import SwiftUI

public enum FeedbackCategory: String, CaseIterable, Sendable {
    case bug
    case featureRequest
    case feedback
    case other

    public var localizedTitle: LocalizedStringResource {
        switch self {
        case .bug:
            "feedback.category.bug"
        case .featureRequest:
            "feedback.category.featureRequest"
        case .feedback:
            "feedback.category.feedback"
        case .other:
            "feedback.category.other"
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
