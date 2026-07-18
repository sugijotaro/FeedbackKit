---
name: add-feedbackkit-app-store-review
description: Add an optional App Store review handoff after a successful FeedbackKit submission. Use FeedbackKit's completion action to pass the submitted feedback to host-app code, copy the message only after an explicit user tap, and open the app's App Store write-review page with action=write-review. Use when the user wants a post-submission App Store review button or a persistent manual review link.
metadata:
  short-description: Add App Store review handoff
---

# Add an App Store Review Handoff

Implement this feature in the host application repository. FeedbackKit remains UI-only and must not contain an App Store ID, clipboard implementation, product URL, analytics policy, or app-specific string.

## Confirm the intended behavior

Before editing, confirm whether the user wants:

1. a review button only after a successful FeedbackKit submission;
2. a persistent review link in Settings as well;
3. copying the submitted feedback text before opening the App Store;
4. opening the App Store without copying text.

Do not ask again when the request already specifies these choices. The default for an underspecified request is: post-submission button, copy on explicit tap, then open the App Store review page.

## Apple platform rules

For a button that the person explicitly taps, open the App Store product URL with `action=write-review`:

```text
https://apps.apple.com/app/id<APP_STORE_ID>?action=write-review
```

Apple documents this deep link for manually initiated reviews. Do not call `RequestReviewAction`, `AppStore.requestReview`, or the deprecated `SKStoreReviewController` directly from this button because the system review request may not appear and Apple advises against invoking it as the result of a user action.

Official references:

- https://developer.apple.com/documentation/storekit/requesting-app-store-reviews
- https://developer.apple.com/documentation/storekit/skstorereviewcontroller/requestreview()

The App Store does not provide a supported way to prefill or automatically submit the written review. Copying text to the pasteboard is only a convenience; the person must paste, edit, and submit it themselves.

## Inspect first

Determine:

- the app's numeric App Store ID from its existing product URL, App Store Connect metadata, configuration, or documentation;
- supported Apple platforms;
- where FeedbackKit is presented;
- the host app's localization and dependency-injection conventions;
- whether the app already has a review-link service or Settings review row;
- whether clipboard use has an existing abstraction;
- whether analytics are already used for button taps.

Do not invent an App Store ID. If it cannot be found, request only that missing value or leave one clearly marked host-app configuration point.

## FeedbackKit API

Use the current public API and pin a stable release that provides `onWriteAppStoreReview`:

```swift
FeedbackSheet(
    onSubmit: { feedback in
        try await feedbackSubmissionService.submit(feedback)
    },
    onWriteAppStoreReview: { feedback in
        reviewHandoff.open(feedback)
    }
)
```

FeedbackKit displays the optional review button only after `onSubmit` succeeds and passes the exact submitted `Feedback` value back to the host app when the person taps it.

Do not show the review action after a failed submission.

## Host-app implementation

Create a small host-owned type, adapted to the repository's architecture. For an iOS-only SwiftUI app, a typical implementation is:

```swift
import FeedbackKit
import SwiftUI
import UIKit

@MainActor
struct AppStoreReviewHandoff {
    let appStoreID: String
    let openURL: OpenURLAction

    func open(_ feedback: Feedback) {
        guard
            appStoreID.allSatisfy(\.isNumber),
            let url = URL(
                string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review"
            )
        else {
            return
        }

        UIPasteboard.general.string = feedback.message
        openURL(url)
    }
}
```

Wire it from a SwiftUI view using the environment action:

```swift
@Environment(\.openURL) private var openURL

private var reviewHandoff: AppStoreReviewHandoff {
    AppStoreReviewHandoff(
        appStoreID: appConfiguration.appStoreID,
        openURL: openURL
    )
}
```

Follow the host app's dependency injection rather than introducing a global singleton when an established pattern exists.

For macOS, use the host app's existing pasteboard abstraction or `NSPasteboard`; do not add UIKit to a macOS target. For multiplatform targets, isolate platform-specific pasteboard code with conditional compilation.

## Privacy and product behavior

- Copy text only after the person explicitly taps the review button.
- Keep the review CTA available regardless of feedback category or sentiment. Do not implement review gating that asks only satisfied users for public reviews.
- Do not automatically open the App Store immediately after feedback submission.
- Do not automatically submit, paste, or alter a review.
- Make clear in the UI that App Store reviews are public.
- Do not copy attachments, tokens, email addresses, device identifiers, or hidden metadata.
- If the host app already detects sensitive content, omit copying and open only the App Store page when the submitted text is considered unsafe for public reuse.
- Do not log the feedback message when logging the review-button tap.

## Persistent Settings link

When requested, add a separate Settings row that opens the same `action=write-review` URL without copying any previous feedback. A persistent review link is distinct from an in-app system rating prompt.

Do not use submitted feedback retained from an earlier session for the persistent link.

## Error handling

Handle these cases without crashing:

- missing or malformed App Store ID;
- URL creation failure;
- `openURL` reports that the URL was not handled;
- pasteboard unavailable on the current platform;
- the app is not yet published in the current storefront.

Use the host app's localized error or toast conventions. Never use `fatalError` for runtime configuration failure.

## Validation

Before finishing:

1. build the host app on every affected platform;
2. confirm no review button appears when `onWriteAppStoreReview` is omitted;
3. confirm it appears only after successful feedback submission;
4. confirm tapping it passes the trimmed submitted message;
5. confirm the pasteboard changes only after the tap;
6. confirm the generated URL contains the correct numeric ID and `action=write-review`;
7. confirm a failed feedback submission does not expose the review action;
8. confirm no feedback body is written to logs or analytics;
9. confirm the persistent Settings link, when included, does not copy stale feedback;
10. test on a real device when possible because App Store behavior is not fully represented by previews or unit tests.

Report the App Store ID source, files changed, whether copying was enabled, the exact URL shape without secrets, and any device-only verification that remains.
