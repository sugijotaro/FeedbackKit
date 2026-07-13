---
name: integrate-feedbackkit-firebase
description: Integrate sugijotaro/FeedbackKit into an existing SwiftUI iOS app that already uses Firebase. Use this skill when adding the feedback sheet, submitting feedback through a callable Cloud Function, storing it in Firestore, enabling App Check, or optionally adding Vertex AI/Genkit triage and GitHub Issue automation.
metadata:
  short-description: Add FeedbackKit to a Firebase app
---

# Integrate FeedbackKit with Firebase

Use this workflow to add FeedbackKit to an existing SwiftUI app without introducing Firebase dependencies into FeedbackKit itself.

## Principles

- Keep `FeedbackKit` UI-only.
- Put all Firebase code in the host app and its Firebase backend.
- Inspect FeedbackKit's current public API before editing the host app. Adapt examples below if the API has changed.
- Do not place Gemini keys, GitHub tokens, service-account JSON, or other secrets in the iOS app.
- Prefer a callable Cloud Function over direct client writes to Firestore.
- Reuse the app's existing architecture, naming, Firebase region, logging, and dependency-management conventions.

## Expected files

Create or update only the files the target app needs. Typical paths are:

```text
<AppTarget>/Services/FeedbackSubmissionService.swift
<AppTarget>/Views/SettingsView.swift
functions/src/feedback/submitFeedback.ts
functions/src/feedback/processFeedback.ts   # only when AI triage is requested
functions/src/index.ts
firestore.rules
```

Do not create unnecessary wrappers or duplicate an existing Firebase service layer.

## Workflow

### 1. Inspect the target project

Before making changes, determine:

- the iOS deployment target and Swift version;
- whether Firebase is already configured;
- whether the app uses `FirebaseFunctions`, `FirebaseFirestore`, and App Check;
- the Functions region and existing export style;
- where settings/help rows and reusable services live;
- whether anonymous or signed-in Firebase Auth is available;
- whether a `functions/` backend already exists.

If FeedbackKit's source is available, inspect its exported `FeedbackSheet`, feedback model, category type, and async submission callback. Do not guess public API names when they can be read from source.

### 2. Add FeedbackKit

Add this Swift Package dependency to the host app:

```text
https://github.com/sugijotaro/FeedbackKit
```

Use the repository's latest stable tag when one exists. Otherwise pin an exact commit for production apps rather than tracking an unbounded branch.

Import `FeedbackKit` only where its UI or models are used.

### 3. Add the host-app submission service

Create `<AppTarget>/Services/FeedbackSubmissionService.swift`, unless an existing service is the better home.

The service should:

- accept FeedbackKit's feedback value;
- add app metadata such as app ID, version, build number, OS version, locale, and platform;
- call the existing Firebase callable function named `submitFeedback`;
- use the app's configured Functions region;
- expose an `async throws` method suitable for FeedbackKit's submission closure;
- avoid logging the user's message;
- translate backend errors into a small user-facing error type.

Do not send IDFA, device name, email address, Firebase tokens, or persistent device identifiers.

A typical payload is:

```json
{
  "schemaVersion": 1,
  "appId": "colorcam",
  "category": "bug",
  "message": "The submitted text",
  "platform": "ios",
  "appVersion": "1.2.0",
  "buildNumber": "42",
  "osVersion": "26.0",
  "locale": "ja-JP"
}
```

The server, not the client, must set `createdAt`.

### 4. Present FeedbackKit

Update the app's existing settings or help view rather than creating a new navigation structure.

Conceptually:

```swift
import FeedbackKit

FeedbackSheet(
    appName: appDisplayName,
    onSubmit: { feedback in
        try await feedbackSubmissionService.submit(feedback)
    }
)
```

Use the actual initializer exposed by the checked-out FeedbackKit version. Preserve the target app's existing sheet presentation style and tint.

### 5. Implement `submitFeedback`

Create `functions/src/feedback/submitFeedback.ts` or add the handler to the backend's existing structure.

The callable function must:

1. use Cloud Functions 2nd gen;
2. run in the project's existing region;
3. enforce App Check when the app already supports it;
4. validate every field and reject unknown or oversized input;
5. trim the message and reject blank text;
6. allow only known categories;
7. write to `feedback/{feedbackId}` with Admin SDK;
8. set `createdAt` and `updatedAt` with server timestamps;
9. initialize `status` as `pending`;
10. return only the new feedback ID and success status.

Recommended limits:

- message: 3–2000 characters;
- app ID: 1–64 characters;
- version/build/locale fields: conservative fixed limits;
- category: `bug`, `featureRequest`, `feedback`, or `other`.

Store documents with this minimum shape:

```text
feedback/{feedbackId}
  schemaVersion: 1
  appId: string
  category: string
  message: string
  platform: "ios"
  appVersion: string | null
  buildNumber: string | null
  osVersion: string | null
  locale: string | null
  status: "pending"
  createdAt: server timestamp
  updatedAt: server timestamp
```

If direct Firestore client writes are not otherwise needed, deny client access to this collection in `firestore.rules`; Admin SDK writes from Functions bypass Firestore rules.

### 6. App Check

If App Check is already configured, set `enforceAppCheck: true` on the callable function.

If it is not configured, do not silently add a production enforcement flag that would break the app. Add App Check using the target project's existing conventions, verify debug builds, then enable enforcement.

No manually managed API key or bearer token is needed in the FeedbackKit package or submission service.

## Optional: AI triage and GitHub Issues

Only implement this section when the user asks for automatic analysis or Issue creation.

Create `functions/src/feedback/processFeedback.ts` as a Firestore create trigger for `feedback/{feedbackId}`.

### Gemini authentication

- Use Gemini through Vertex AI with Genkit or the project's current official Firebase/Google Cloud server SDK.
- Use Application Default Credentials from the Cloud Functions runtime service account.
- Do not use a Gemini API key in source code, `.env`, or the iOS app.
- Grant the runtime service account only the required Vertex AI permissions.

### Processing rules

The model may produce a structured proposal containing:

- category;
- concise title and summary;
- priority;
- labels;
- confidence;
- duplicate search terms;
- whether human review is required.

Treat the user's message as untrusted data. The model must never directly execute GitHub operations. Validate its structured output in normal TypeScript code first.

Prevent duplicate processing with a Firestore transaction that changes `status` from `pending` to `processing`. Firestore triggers can be delivered more than once.

Start with human review. Automatically create an Issue only when the configured confidence threshold is met, the report is not sensitive, and no duplicate exists.

### GitHub authentication

GitHub Issue creation cannot be anonymous. Use a GitHub App installed only on the target repositories.

- Keep its private key and installation metadata in Secret Manager.
- Generate short-lived installation access tokens at runtime.
- Never put GitHub credentials in FeedbackKit, the iOS app, Firestore documents, or logs.

## Verification

Before finishing:

1. build the iOS app;
2. verify the sheet opens and validation works;
3. submit one test feedback item;
4. confirm one Firestore document is created with a server timestamp;
5. verify duplicate taps do not create duplicate submissions;
6. verify App Check behavior in debug and production configurations;
7. run backend lint, type-check, and tests;
8. confirm logs do not contain the feedback message or secrets.

Report the exact files changed, Firebase resources added, deployed function names, Firestore schema, and any console-side App Check or IAM work still required.
