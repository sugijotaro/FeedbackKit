---
name: integrate-feedbackkit-firebase
description: Integrate sugijotaro/FeedbackKit into an existing SwiftUI Firebase app by adding a FeedbackSheet entry point, a Swift FirebaseFunctions submitter, and a callable Cloud Function named submitFeedback that stores validated feedback in Firestore with a pending status ready for optional AI triage. Use when FeedbackKit submissions show NOT_FOUND, when adding the backend for FeedbackKit, or when wiring FeedbackKit to Firebase.
metadata:
  short-description: Add FeedbackKit backend on Firebase
---

# Integrate FeedbackKit with Firebase

Use this workflow when an app already shows `FeedbackSheet` and needs a working Firebase backend, or when submission fails with `not found` / `FunctionsErrorCode.notFound`.

Implement the integration; do not only document it.

## Required Checks

1. Confirm the app's Firebase project from `GoogleService-Info.plist` (`PROJECT_ID`).
2. Pick one callable function name and region. Default for FeedbackKit integrations:
   - function name: `submitFeedback`
   - region: `asia-northeast1`
3. Choose a stable app identifier such as `colorcam`. This becomes `appId` in Firestore and is later used to route feedback to the correct GitHub repository.
4. Ensure Swift and Firebase Functions use the same name and region:
   - Swift: `Functions.functions(region: "asia-northeast1").httpsCallable("submitFeedback")`
   - Functions: `onCall({ region: "asia-northeast1" }, async (request) => { ... })`

If region is omitted in Swift, Firebase looks in the SDK default region. A deployed function in another region will return `not found`.

## Firebase Functions Files

If the app repo has no Firebase Functions setup, create a dedicated `firebase/` directory in the app repo and add Firebase-related files inside it:

```text
firebase/.firebaserc
firebase/firebase.json
firebase/firestore.rules
firebase/functions/package.json
firebase/functions/src/index.ts
firebase/functions/tsconfig.json
```

Use TypeScript by default. If the app repo already has Firebase Functions in another location or language, follow the existing setup instead of moving unrelated files.

Run Firebase CLI commands from the `firebase/` directory unless the repo already has a different convention.

### `firebase/.firebaserc`

Set the default project to the app's Firebase project id:

```json
{
  "projects": {
    "default": "PROJECT_ID"
  }
}
```

### `firebase/firebase.json`

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "runtime": "nodejs20"
    }
  ],
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

Paths in `firebase/firebase.json` are relative to the `firebase/` directory, so `source: "functions"` points to `firebase/functions`.

### `firebase/functions/package.json`

Use a TypeScript Functions package:

```json
{
  "name": "app-feedback-functions",
  "private": true,
  "engines": {
    "node": "20"
  },
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "lint": "tsc --noEmit",
    "serve": "npm run build && firebase emulators:start --only functions,firestore",
    "deploy": "npm run build && firebase deploy --only functions:submitFeedback,firestore:rules"
  },
  "dependencies": {
    "firebase-admin": "^13.0.0",
    "firebase-functions": "^6.0.1"
  },
  "devDependencies": {
    "typescript": "^5.7.0"
  }
}
```

Use versions compatible with the existing project rather than downgrading or duplicating dependencies.

### `firebase/functions/tsconfig.json`

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2020",
    "lib": ["es2020"],
    "outDir": "lib",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"]
}
```

## Swift Submitter

Create a small service in the host app, for example:

```text
<AppTarget>/Services/FeedbackSubmissionService.swift
```

It should call the selected region and function:

```swift
try await Functions.functions(region: "asia-northeast1")
    .httpsCallable("submitFeedback")
    .call(payload)
```

Build a payload containing:

```text
schemaVersion: 1
appId: stable app identifier
category: FeedbackKit category raw value
message: trimmed feedback message
platform: "ios"
appVersion: app marketing version when available
buildNumber: app build number when available
osVersion: OS version when available
locale: current locale identifier when available
```

Do not send IDFA, device name, email address, Firebase tokens, or persistent device identifiers. Do not log or store raw feedback text in Analytics. Logging only category and success/failure is acceptable.

FeedbackKit remains UI-only. Firebase code belongs to the host app.

## Callable Function

Implement `submitFeedback` with these properties:

- Use `firebase-functions/v2/https`, `firebase-admin`, and `logger`.
- Do not require App Check. If the target app already uses App Check successfully, preserve its convention, but do not introduce enforcement by default.
- Validate every field instead of trusting the Swift client.
- Require `schemaVersion` to be the supported value.
- Require `appId` and limit it to a conservative length and safe character set.
- Allow only `bug`, `featureRequest`, `feedback`, `other` categories.
- Trim the message and require 3...2000 characters.
- Accept only known optional metadata fields with conservative length limits.
- Reject unknown, malformed, or oversized input with `HttpsError("invalid-argument", ...)`.
- Add lightweight server-side rate limiting so anonymous apps cannot spam.
- Throw stable error codes such as `invalid-argument`, `resource-exhausted`, and `internal`.
- Set timestamps on the server.
- Return only `{ success: true, feedbackId }`.

Write this minimum Firestore shape:

```text
feedback/{feedbackId}
  schemaVersion: 1
  appId: string
  category: "bug" | "featureRequest" | "feedback" | "other"
  message: string
  platform: "ios"
  appVersion: string | null
  buildNumber: string | null
  osVersion: string | null
  locale: string | null
  status: "pending"
  processingAttempts: 0
  createdAt: server timestamp
  updatedAt: server timestamp
```

`status: "pending"` is required so the optional `automate-feedback-github-issues` skill can claim and process the document later.

Do not store raw IP addresses. If rate limiting uses a request-derived address, hash it before storing the limiter key, apply expiry or cleanup, and do not copy it into the feedback document.

## Firestore Rules

If feedback writes only happen through Admin SDK in Cloud Functions, users do not need direct Firestore access. Merge locked-down rules with the app's existing rules:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /feedback/{document=**} {
      allow read, write: if false;
    }
  }
}
```

Do not overwrite unrelated rules. Admin SDK writes from Functions bypass client Firestore rules.

## Validation

1. Run package installation in `firebase/functions/`.
2. Run `npm run lint` and `npm run build` from `firebase/functions/`.
3. Build the iOS app.
4. Run the emulator when available and submit a valid and invalid payload.
5. Deploy from `firebase/` when ready:

```bash
firebase deploy --only functions:submitFeedback,firestore:rules
```

If `firebase` is not installed, use `npx firebase-tools deploy ...`.

6. Submit one item from the app and confirm exactly one `feedback/{feedbackId}` document appears with server timestamps and `status: "pending"`.

## Optional AI and GitHub automation

After Firestore storage works, use the `automate-feedback-github-issues` skill to add:

- Gemini triage through Vertex AI without a Gemini API key;
- priority, title, summary, and duplicate-key generation;
- idempotent Firestore processing;
- GitHub App authentication;
- automatic GitHub Issue creation for qualifying feedback.

Keep this as a separate second stage so storage remains reliable when Vertex AI or GitHub is unavailable.

## Troubleshooting

- `not found`: Swift region/name does not match the deployed callable, or it is not deployed.
- `permission-denied`: auth or App Check enforcement exists in the project but the app is not satisfying it.
- `resource-exhausted`: rate limit is working.
- `invalid-argument`: payload validation failed.
- feedback never leaves `pending`: the optional processor is not deployed or failed before claiming the document.
