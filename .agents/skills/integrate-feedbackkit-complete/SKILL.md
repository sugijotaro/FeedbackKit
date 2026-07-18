---
name: integrate-feedbackkit-complete
description: "Integrate FeedbackKit end to end into an existing SwiftUI app: add the Swift Package and sheet UI, submit through Firebase Cloud Functions, store feedback in Firestore, analyze it with Gemini on Vertex AI without a Gemini API key, and create qualifying GitHub Issues through a GitHub App. Use when the user provides the FeedbackKit repository URL and asks to implement the whole workflow."
metadata:
  short-description: Add FeedbackKit end to end
---

# Integrate FeedbackKit End to End

Implement the complete workflow in the host application repository. Do not stop after adding only the package, UI, documentation, Firestore storage, or AI code.

## Source

Use the latest stable semantic-version release of:

```text
https://github.com/sugijotaro/FeedbackKit
```

Read the current public API before editing the host app. Add FeedbackKit through Swift Package Manager; do not copy its source files into the app.

## Completion target

```text
SwiftUI settings/help entry
  -> FeedbackKit FeedbackSheet
  -> host-app FirebaseFunctions submitter
  -> callable submitFeedback
  -> Firestore feedback/{feedbackId}
  -> processFeedback trigger
  -> Gemini on Vertex AI using runtime ADC
  -> deterministic policy and duplicate checks
  -> GitHub App
  -> qualifying GitHub Issue
```

FeedbackKit remains UI-only. Firebase, Vertex AI, GitHub, app identifiers, repository names, and product-specific strings belong to the host project.

## Work in this order

### 1. Inspect the host repository

Determine:

- SwiftUI target, supported platforms, and minimum OS version;
- existing Swift Package and Xcode project conventions;
- settings, help, support, or account screen where feedback belongs;
- Firebase project and `GoogleService-Info.plist` configuration;
- existing Functions language, codebase, runtime, module system, region, and deploy scripts;
- authoritative Firestore rules source;
- target GitHub owner and repository;
- available Firebase CLI, gcloud, and GitHub authentication.

Preserve the existing architecture. Do not move unrelated files or replace unrelated Firestore rules.

### 2. Add the Swift Package and UI

Add the FeedbackKit repository as an SPM dependency and link the `FeedbackKit` product to the app target.

Present the sheet from the existing settings/help UI:

```swift
FeedbackSheet { feedback in
    try await feedbackSubmissionService.submit(feedback)
}
```

Use the host app's existing tint, localization, navigation, and error conventions. Do not add Firebase code to FeedbackKit itself.

### 3. Add Firebase storage

Read and apply the repository Skill:

```text
.agents/skills/integrate-feedbackkit-firebase/SKILL.md
```

Implement the Swift `FirebaseFunctions` submitter and callable `submitFeedback`. Store validated documents in `feedback/{feedbackId}` with `status: "pending"`.

App Check is optional and must not be introduced solely for this feature. Keep client Firestore access closed. Merge rules into the host project's authoritative rules source rather than replacing the active ruleset.

### 4. Add Gemini triage and GitHub automation

Read and apply:

```text
.agents/skills/automate-feedback-github-issues/SKILL.md
```

Use Cloud Functions 2nd gen, Node 22 or newer, `@google/genai` in Vertex AI mode, and runtime Application Default Credentials. Do not add a Gemini API key or service-account JSON.

Use a GitHub App with Issues read/write. Store only its private key in Secret Manager. Start with `autoCreateIssues: false`, inspect triage output, then enable automatic creation only after controlled tests pass.

### 5. Validate locally and in CI

Before reporting completion:

- resolve Swift packages and build the host app, not only the package;
- run Functions dependency installation, type-check, tests when present, and production build;
- validate String Catalog JSON;
- verify blank, oversized, malformed, rapid-repeat, sensitive, ambiguous, praise, actionable, and duplicate submissions;
- verify raw feedback, request addresses, secrets, model output, and installation tokens are not logged;
- verify Firestore rules preserve unrelated host-app access;
- verify retries cannot create a second GitHub Issue.

Add or update CI so the integration remains buildable.

### 6. Deploy when credentials are available

When authenticated Firebase CLI, gcloud, and GitHub access are available:

- enable Vertex AI;
- grant the Functions runtime identity permission to invoke Vertex AI;
- create and install the GitHub App;
- set the GitHub App private key in Secret Manager;
- create the server-only app configuration document;
- deploy Functions;
- test triage-only mode;
- enable automatic Issue creation;
- complete an end-to-end submission test.

Do not claim deployment or end-to-end completion unless these operations actually succeeded.

If required credentials or console permissions are unavailable, finish all repository changes and validation that can be performed, then report only the exact external actions still blocked. Do not replace missing credentials with hard-coded keys, personal tokens, or committed secret files.

## Definition of done

The task is complete only when:

1. FeedbackKit is linked to the correct app target.
2. The sheet is reachable from the intended UI.
3. A valid submission reaches the callable Function.
4. Firestore stores a validated `pending` document.
5. The processor produces structured triage through Vertex AI.
6. Sensitive and non-actionable feedback does not create Issues.
7. A controlled actionable report creates exactly one GitHub Issue after automation is enabled.
8. Duplicate and retried events do not create another Issue.
9. Host app and Functions builds pass.
10. No app-specific values or secrets were added to FeedbackKit itself.

Report changed files, deployed resources, tests performed, and any external credential-bound action that could not be completed.
