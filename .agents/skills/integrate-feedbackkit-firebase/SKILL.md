---
name: integrate-feedbackkit-firebase
description: Integrate sugijotaro/FeedbackKit into an existing SwiftUI Firebase app by adding a FeedbackSheet entry point, a Swift FirebaseFunctions submitter, and a callable Cloud Function named submitFeedback that stores validated feedback in Firestore with a pending status ready for optional AI triage. Use when FeedbackKit submissions show NOT_FOUND, when adding the backend for FeedbackKit, or when wiring FeedbackKit to Firebase.
metadata:
  short-description: Add FeedbackKit backend on Firebase
---

# Integrate FeedbackKit with Firebase

Implement the integration; do not only document it.

Use this workflow when an app already shows `FeedbackSheet` and needs a working Firebase backend, or when submission fails with `not found` / `FunctionsErrorCode.notFound`.

## Inspect first

1. Read FeedbackKit's current public API instead of guessing initializer or model names.
2. Confirm the Firebase project from `GoogleService-Info.plist` (`PROJECT_ID`) or the app's existing Firebase configuration.
3. Inspect existing Functions location, language, module system, Node runtime, region, and deployment conventions.
4. Inspect current Firestore rules before editing or deploying them.
5. Identify the existing settings/help view and Firebase service layer.
6. Choose a stable lowercase `appId`, such as `colorcam`.

Do not move unrelated Firebase files, replace an existing architecture, or overwrite unrelated security rules.

## Function contract

Default when the app has no established convention:

```text
function: submitFeedback
region: asia-northeast1
```

Swift and Functions must use the same name and region:

```swift
Functions.functions(region: "asia-northeast1")
    .httpsCallable("submitFeedback")
```

```ts
onCall({ region: "asia-northeast1" }, async (request) => {
  // ...
});
```

A mismatch returns `not found`.

## Typical files

Adapt to the repository. For a new TypeScript backend:

```text
firebase/firebase.json
firebase/functions/package.json
firebase/functions/package-lock.json
firebase/functions/tsconfig.json
firebase/functions/src/index.ts
firebase/functions/src/submitFeedback.ts
firebase/firestore.rules
<AppTarget>/Features/Feedback/FeedbackSubmissionService.swift
```

Keep FeedbackKit UI-only. Firebase code belongs to the host app.

## Functions runtime

Use Node 22 or the repository's newer Firebase-supported runtime. Do not downgrade an existing backend.

A minimal package commonly includes:

```json
{
  "type": "module",
  "engines": { "node": "22" },
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "lint": "tsc --noEmit",
    "deploy": "npm run build && firebase deploy --only functions"
  },
  "dependencies": {
    "firebase-admin": "^14.1.0",
    "firebase-functions": "^7.2.5"
  },
  "devDependencies": {
    "@types/node": "^22.15.0",
    "typescript": "^5.8.3"
  }
}
```

Use current compatible versions and commit the lockfile. CI should use `npm ci`.

## Swift submitter

Create a small service in the host app, for example:

```text
<AppTarget>/Features/Feedback/FeedbackSubmissionService.swift
```

It should expose an `async throws` method compatible with FeedbackKit's submission closure and send:

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

Do not send IDFA, device name, email address, Firebase tokens, or persistent device identifiers. Do not log raw feedback in Analytics or application logs.

Present FeedbackKit from the app's existing settings/help UI. Preserve the app's tint and navigation conventions.

## Callable Function

Implement `submitFeedback` with these requirements:

- use Cloud Functions 2nd gen, Firebase Admin SDK, and structured logging;
- do not require App Check by default;
- preserve existing App Check enforcement only when the app already supports it reliably;
- validate the payload as an exact object and reject unknown fields;
- require `schemaVersion: 1`;
- validate `appId` against a conservative safe-character pattern;
- allow only `bug`, `featureRequest`, `feedback`, and `other`;
- trim and require a message of 3 through 2,000 characters;
- validate optional metadata with conservative limits;
- set timestamps on the server;
- return only `{ success: true, feedbackId }`;
- emit stable `HttpsError` codes such as `invalid-argument`, `resource-exhausted`, and `internal`.

Add lightweight server-side rate limiting for anonymous apps. Prefer Firebase Auth UID when available. Otherwise hash the runtime-resolved request address; never store a raw IP address or copy it into the feedback document. Add an expiry timestamp and document Firestore TTL cleanup.

Write:

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

`status: "pending"` is required for the optional `automate-feedback-github-issues` processor.

## Firestore rules safety

Feedback is written by Firebase Admin SDK, so mobile clients do not need direct access. The feedback collections should be server-only:

```text
match /feedback/{document=**} {
  allow read, write: if false;
}
match /feedbackRateLimits/{document=**} {
  allow read, write: if false;
}
```

However, Firebase CLI rule deployment replaces the currently deployed Firestore ruleset. Therefore:

1. inspect the active rules in the Firebase console or the repository's authoritative rules source;
2. merge the feedback blocks into those existing rules;
3. preserve every unrelated application rule;
4. test the merged rules with the Emulator or Rules Playground;
5. deploy Rules separately from Functions.

Do not make `firebase deploy --only functions,firestore:rules` the default command for an existing project.

Deploy Functions first:

```bash
firebase deploy --only functions:submitFeedback
```

Deploy the reviewed merged Rules separately:

```bash
firebase deploy --only firestore:rules
```

If no authoritative local rules file exists, do not invent a replacement ruleset and deploy it. Leave a clearly marked rules snippet and report that console review is required.

## Validation

Before finishing:

1. install dependencies with `npm ci` or the repository's package manager;
2. run TypeScript type-check and build;
3. build the iOS app, not only resolve packages;
4. submit valid, blank, oversized, malformed, and rapid-repeat payloads through the Emulator when available;
5. deploy only the callable Function first;
6. submit one item from the app and confirm exactly one `feedback/{feedbackId}` document with server timestamps and `status: "pending"`;
7. review and merge Firestore rules before any Rules deployment;
8. confirm logs contain neither the message nor request address.

Report exact files changed, Function name and region, Firestore schema, rate-limit behavior, deployment results, and any Firebase project or rules work that still requires console access.

## Optional AI and GitHub automation

After storage works, use `automate-feedback-github-issues` to add:

- Gemini triage through Vertex AI without a Gemini API key;
- structured prioritization and sensitive-data checks;
- semantic and feedback-specific idempotency;
- GitHub App authentication;
- staged automatic GitHub Issue creation.

Keep this as a separate second stage so feedback storage remains reliable when Vertex AI or GitHub is unavailable.

## Troubleshooting

- `not found`: Swift name/region does not match the deployed callable, or it is not deployed.
- `permission-denied`: existing auth or App Check enforcement is not satisfied.
- `resource-exhausted`: the rate limit is working.
- `invalid-argument`: payload validation failed.
- feedback remains `pending`: the optional processor is absent or failed before claiming it.
