import Foundation

enum FeedbackValidation {
    static let minimumMessageLength = 3
    static let maximumMessageLength = 2_000

    static func trimmedMessage(_ message: String) -> String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValidMessage(_ message: String) -> Bool {
        let trimmed = trimmedMessage(message)
        return trimmed.count >= minimumMessageLength
            && message.count <= maximumMessageLength
    }

    static func limitedMessage(_ message: String) -> String {
        String(message.prefix(maximumMessageLength))
    }
}
