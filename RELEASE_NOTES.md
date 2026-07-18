# FeedbackKit v1.1.0

FeedbackKit is a reusable SwiftUI feedback sheet with Agent Skills for optional Firebase storage, Gemini triage on Vertex AI, and GitHub Issue automation.

## Highlights

- Simple UI-only Swift Package with no Firebase dependency.
- `FeedbackSheet` now uses the compact `FeedbackSheet { feedback in ... }` API.
- Japanese and English localization through `Localizable.xcstrings`.
- Input validation, character limits, loading state, completion state, error preservation, Dynamic Type, VoiceOver, dark mode, and keyboard handling.
- New `integrate-feedbackkit-complete` Agent Skill for end-to-end host-app integration.
- Existing Skills for Firestore-only integration and AI-to-GitHub automation.
- Vertex AI authentication through the Cloud Functions runtime identity, without a Gemini API key.
- App Check remains optional.
- Safer Firestore Rules guidance that avoids replacing an existing app ruleset.
- Idempotent GitHub Issue creation with sensitive-data checks and staged rollout.
- CI validation for Swift tests, String Catalog JSON, Skill discovery, and public API consistency.

## Basic usage

```swift
FeedbackSheet { feedback in
    try await submitFeedback(feedback)
}
```

## Agent Skill installation

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill integrate-feedbackkit-complete \
  --agent codex \
  -y
```

Firebase, Vertex AI, and GitHub integrations remain in the host application repository. FeedbackKit itself stays UI-only and contains no product-specific identifiers or secrets.
