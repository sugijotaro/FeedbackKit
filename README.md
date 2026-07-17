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

    private var appDisplayName: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleDisplayName"
        ) as? String ?? "App"
    }

    var body: some View {
        Button("ご意見・ご要望") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            FeedbackSheet(appName: appDisplayName) { feedback in
                print(feedback.category)
                print(feedback.message)
            }
        }
    }
}
```

## Async Submission

```swift
FeedbackSheet(appName: appDisplayName) { feedback in
    try await submitFeedback(feedback)
}
```

Firebase, API calls, and other network handling are implemented by the host app. FeedbackKit itself remains UI-only.

## Agent Skills

This repository also contains Agent Skills for implementing the Firebase backend in an existing app repository.

List the available skills:

```bash
npx skills add sugijotaro/FeedbackKit --list
```

### 1. Store feedback in Firestore

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill integrate-feedbackkit-firebase \
  --agent codex \
  -y
```

This skill adds the Swift FirebaseFunctions submitter, callable `submitFeedback` function, validation, anonymous rate limiting without requiring App Check, locked-down Firestore rules, and the `feedback/{feedbackId}` schema.

### 2. Analyze feedback and create GitHub Issues

```bash
npx skills add sugijotaro/FeedbackKit \
  --skill automate-feedback-github-issues \
  --agent codex \
  -y
```

This second skill extends the Firebase backend with:

- a Firestore create trigger running on Cloud Functions 2nd gen;
- Gemini analysis through Vertex AI using the Cloud Functions runtime service account;
- the official `@google/genai` SDK, without a Gemini API key in the app or source code;
- structured triage, prioritization, deterministic sensitive-data checks, and label allowlists;
- semantic duplicate locks and feedback-specific GitHub operation records;
- GitHub App authentication with short-lived installation tokens;
- staged rollout with automatic Issue creation disabled until triage quality is reviewed;
- automatic GitHub Issue creation for qualifying bug reports and feature requests.

The GitHub App private key must be stored in Secret Manager. GitHub cannot create Issues without authentication.

Run the first skill before the second when the app does not yet store FeedbackKit submissions in Firestore.
