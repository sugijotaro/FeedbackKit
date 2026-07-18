# FeedbackKit v1.2.0

FeedbackKit remains a reusable, UI-only SwiftUI feedback sheet. This release adds an optional post-submission App Store review handoff and expands the Agent Skills into a scope-aware integration workflow.

## Highlights

- New optional `onWriteAppStoreReview` completion action.
- The review action appears only after a successful submission.
- The exact submitted `Feedback` value is passed back to host-owned code after an explicit tap.
- FeedbackKit keeps App Store IDs, clipboard APIs, review URLs, analytics policy, and product-specific values outside the package.
- Japanese and English copy explains that App Store reviews are public.
- New `add-feedbackkit-app-store-review` Agent Skill.
- The complete integration Skill now asks which capabilities the user wants before editing the host project.
- Scope choices cover UI only, Firebase and Firestore storage, Gemini and GitHub Issue automation, post-submission App Store review handoff, persistent Settings review link, or all capabilities.
- CI validates all four Skills through `npx skills`, String Catalog JSON, Swift tests, the optional review API, and the UI-only package boundary.

## Basic usage

```swift
FeedbackSheet { feedback in
    try await submitFeedback(feedback)
}
```

## Optional App Store review handoff

```swift
FeedbackSheet(
    onSubmit: { feedback in
        try await submitFeedback(feedback)
    },
    onWriteAppStoreReview: { feedback in
        reviewHandoff.open(feedback)
    }
)
```

The host app may copy `feedback.message` only after the tap and open:

```text
https://apps.apple.com/app/id<APP_STORE_ID>?action=write-review
```

The App Store does not provide a supported way to prefill or automatically submit the written review.

## Agent Skill installation

Choose an implementation scope:

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill integrate-feedbackkit-complete \
  --agent codex \
  -y
```

Install only the App Store review handoff Skill:

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill add-feedbackkit-app-store-review \
  --agent codex \
  -y
```

Firebase, Vertex AI, GitHub, App Store metadata, clipboard handling, and secrets remain in the host application repository.
