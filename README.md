# FeedbackKit

FeedbackKit is a SwiftUI package for showing an in-app feedback sheet. It provides only the UI and passes submitted feedback back to the host app.

## Installation

Add this repository as a Swift Package dependency, then add the `FeedbackKit` library to your app target.

## Basic Usage

```swift
import SwiftUI
import FeedbackKit

struct SettingsView: View {
    @State private var isPresented = false

    var body: some View {
        Button("ご意見・ご要望") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            FeedbackSheet { feedback in
                print(feedback.category)
                print(feedback.message)
            }
        }
    }
}
```

## Async Submission

```swift
FeedbackSheet { feedback in
    try await submitFeedback(feedback)
}
```

Firebase, API calls, and other network handling are implemented by the host app. FeedbackKit itself remains UI-only.

## Shake to Report

On iOS, attach `feedbackSheetOnShake` near the root of the app's view hierarchy. A shake opens a medium-height prompt inspired by familiar “report a problem” flows. The prompt can open `FeedbackSheet` or disable future shake detection.

```swift
struct RootView: View {
    @AppStorage("isShakeFeedbackEnabled") private var isShakeFeedbackEnabled = true

    var body: some View {
        ContentView()
            .feedbackSheetOnShake(isEnabled: $isShakeFeedbackEnabled) { feedback in
                try await submitFeedback(feedback)
            }
    }
}
```

The binding controls shake detection at runtime and lets the person disable it from the prompt. The host app owns persistence, submission, analytics, and any app-specific policy. Apply the modifier once; adding it to multiple visible views can present duplicate prompts.

## Optional App Store Review Action

A host app can add an optional action to the successful-completion screen:

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

FeedbackKit only displays the button and passes the submitted `Feedback` value back after an explicit tap. The host app owns its App Store ID, clipboard handling, review URL, privacy policy, and error handling.

For a manually initiated review, Apple documents opening the product page with:

```text
https://apps.apple.com/app/id<APP_STORE_ID>?action=write-review
```

The App Store does not provide a supported way to prefill or automatically submit the written review.

## Agent Skills

This repository contains Agent Skills for different integration scopes.

List the available skills:

```bash
npx skills add sugijotaro/FeedbackKit --list
```

### Choose an implementation scope

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill integrate-feedbackkit-complete \
  --agent codex \
  -y
```

This orchestration Skill first asks which capabilities the user wants:

- feedback form UI only;
- Firebase and Firestore storage;
- Gemini triage and GitHub Issue automation;
- a post-submission App Store review handoff;
- a persistent Settings review link;
- or all capabilities.

It then applies only the selected Skills and validates the corresponding implementation.

### Store feedback in Firestore

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill integrate-feedbackkit-firebase \
  --agent codex \
  -y
```

This Skill adds the Swift FirebaseFunctions submitter, callable `submitFeedback` function, validation, anonymous rate limiting without requiring App Check, server-only Firestore storage, and the `feedback/{feedbackId}` schema.

### Add AI triage and GitHub Issues

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill automate-feedback-github-issues \
  --agent codex \
  -y
```

This Skill extends an existing Firebase feedback backend with:

- a Firestore create trigger running on Cloud Functions 2nd gen;
- Gemini analysis through Vertex AI using the Cloud Functions runtime service account;
- the official `@google/genai` SDK, without a Gemini API key in the app or source code;
- structured triage, prioritization, deterministic sensitive-data checks, and label allowlists;
- semantic duplicate locks and feedback-specific GitHub operation records;
- GitHub App authentication with short-lived installation tokens;
- staged rollout with automatic Issue creation disabled until triage quality is reviewed;
- automatic GitHub Issue creation for qualifying bug reports and feature requests.

### Add an App Store review handoff

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill add-feedbackkit-app-store-review \
  --agent codex \
  -y
```

This Skill adds host-owned App Store ID configuration, optional message copying after an explicit tap, the `action=write-review` deep link, privacy safeguards, and an optional persistent Settings review link.

The GitHub App private key must be stored in Secret Manager. GitHub cannot create Issues without authentication.
