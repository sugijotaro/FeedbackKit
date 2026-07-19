import XCTest
@testable import FeedbackKit

final class FeedbackKitTests: XCTestCase {
    func testCategoryRawValuesRemainStable() {
        XCTAssertEqual(FeedbackCategory.bug.rawValue, "bug")
        XCTAssertEqual(FeedbackCategory.featureRequest.rawValue, "featureRequest")
        XCTAssertEqual(FeedbackCategory.feedback.rawValue, "feedback")
        XCTAssertEqual(FeedbackCategory.other.rawValue, "other")
    }

    func testFeedbackStoresSubmittedValues() {
        let feedback = Feedback(category: .bug, message: "A reproducible issue")

        XCTAssertEqual(feedback.category, .bug)
        XCTAssertEqual(feedback.message, "A reproducible issue")
    }

    func testWhitespaceOnlyMessageIsInvalid() {
        XCTAssertFalse(FeedbackValidation.isValidMessage("  \n  "))
    }

    func testMessageShorterThanMinimumIsInvalid() {
        XCTAssertFalse(FeedbackValidation.isValidMessage("ab"))
    }

    func testMinimumLengthMessageIsValidAfterTrimming() {
        XCTAssertTrue(FeedbackValidation.isValidMessage("  abc  "))
        XCTAssertEqual(FeedbackValidation.trimmedMessage("  abc  "), "abc")
    }

    func testMaximumLengthMessageIsValid() {
        let message = String(repeating: "a", count: FeedbackValidation.maximumMessageLength)
        XCTAssertTrue(FeedbackValidation.isValidMessage(message))
    }

    func testOverMaximumLengthMessageIsInvalidAndCanBeLimited() {
        let message = String(repeating: "a", count: FeedbackValidation.maximumMessageLength + 1)

        XCTAssertFalse(FeedbackValidation.isValidMessage(message))
        XCTAssertEqual(
            FeedbackValidation.limitedMessage(message).count,
            FeedbackValidation.maximumMessageLength
        )
    }

    func testLocalizedCategoryTitlesAreAvailable() {
        for category in FeedbackCategory.allCases {
            XCTAssertFalse(category.localizedTitle.isEmpty)
        }
    }

    @MainActor
    func testFeedbackSheetSupportsOptionalReviewActionForAsyncSubmission() {
        let submit: (Feedback) async throws -> Void = { _ in }
        let review: (Feedback) -> Void = { _ in }

        _ = FeedbackSheet(
            onSubmit: submit,
            onWriteAppStoreReview: review
        )
    }

    @MainActor
    func testFeedbackSheetSupportsOptionalReviewActionForSyncSubmission() {
        let submit: (Feedback) -> Void = { _ in }
        let review: (Feedback) -> Void = { _ in }

        _ = FeedbackSheet(
            onSubmit: submit,
            onWriteAppStoreReview: review
        )
    }

    #if os(iOS)
    @MainActor
    func testShakePresentationSupportsRuntimeEnablementAndAsyncSubmission() {
        let submit: (Feedback) async throws -> Void = { _ in }

        _ = EmptyView().feedbackSheetOnShake(
            isEnabled: .constant(true),
            onSubmit: submit
        )
    }

    @MainActor
    func testShakePresentationSupportsRuntimeEnablementAndSyncSubmission() {
        let submit: (Feedback) -> Void = { _ in }

        _ = EmptyView().feedbackSheetOnShake(
            isEnabled: .constant(false),
            onSubmit: submit
        )
    }
    #endif
}
