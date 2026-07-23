# FeedbackKit v1.3.0

This minor release adds an optional shake-to-report entry point on iOS, so people can reach the feedback form from anywhere in a host app without hunting for a settings screen.

## Highlights

- New `feedbackSheetOnShake(isEnabled:onSubmit:onWriteAppStoreReview:)` View modifier for iOS.
- A shake presents a medium-detent prompt with two actions: reporting a problem opens `FeedbackSheet` with the `.bug` category preselected, while the secondary action opens it with `.feedback`.
- The prompt includes a toggle so the person can turn shake detection off without leaving the flow.
- `FeedbackSheet` gains an `initialCategory` parameter, defaulting to `.feedback`. Existing initializers remain source compatible.
- `FeedbackSheet` now uses only the `.large` presentation detent so long messages stay readable while typing.
- Localized strings for the shake prompt were added to the package String Catalog.

## Host app responsibilities

The modifier takes a `Binding<Bool>`, and the host app owns persistence:

```swift
@AppStorage("isShakeFeedbackEnabled") private var isShakeFeedbackEnabled = true

ContentView()
    .feedbackSheetOnShake(isEnabled: $isShakeFeedbackEnabled) { feedback in
        try await feedbackSubmissionService.submit(feedback)
    }
```

Attach the modifier once near the root of the visible view hierarchy; applying it to multiple simultaneously visible views can present duplicate prompts. Because the prompt lets people disable shake detection, host apps should also expose a persistent Settings toggle bound to the same stored value so the feature can be re-enabled later.

## Agent Skills

- `integrate-feedbackkit-complete` documents shake-to-report as an optional scope, including the required host Settings toggle and its verification steps.

FeedbackKit itself remains a reusable, UI-only SwiftUI package. Firebase, Vertex AI, GitHub, App Store metadata, and product-specific values remain in the host application repository.
