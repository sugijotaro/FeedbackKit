---
name: integrate-feedbackkit-firebase
description: Integrate sugijotaro/FeedbackKit into an existing SwiftUI Firebase app by adding a FeedbackSheet entry point, a Swift FirebaseFunctions submitter, and a Firebase callable Cloud Function named submitFeedback that stores feedback in Firestore. Use when FeedbackKit submissions show NOT_FOUND, when adding the backend for FeedbackKit, or when wiring FeedbackKit to Firebase.
metadata:
  short-description: Add FeedbackKit backend on Firebase
---

# Integrate FeedbackKit with Firebase

Use this workflow when an app already shows `FeedbackSheet` and needs a working Firebase backend, or when submission fails with `not found` / `FunctionsErrorCode.notFound`.

## Required Checks

1. Confirm the app's Firebase project from `GoogleService-Info.plist` (`PROJECT_ID`).
2. Pick one callable function name and region. Default for FeedbackKit integrations:
   - function name: `submitFeedback`
   - region: `asia-northeast1`
3. Ensure Swift and Firebase Functions use the same name and region:
   - Swift: `Functions.functions(region: "asia-northeast1").httpsCallable("submitFeedback")`
   - Functions: `onCall({ region: "asia-northeast1" }, async (request) => { ... })`

If region is omitted in Swift, Firebase looks in the SDK default region. A deployed function in another region will return `not found`.

## Firebase Functions Files

If the app repo has no Firebase Functions setup, add:

```text
.firebaserc
firebase.json
functions/package.json
functions/index.js
```

Use JavaScript unless the repo already has TypeScript Functions.

### `.firebaserc`

Set the default project to the app's Firebase project id:

```json
{
  "projects": {
    "default": "PROJECT_ID"
  }
}
```

### `firebase.json`

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

### Callable Function

Implement `submitFeedback` with these properties:

- Validate `category` and `message`.
- Allow only `bug`, `featureRequest`, `feedback`, `other`.
- Trim message and require 3...2000 characters.
- Store in Firestore collection `feedback`.
- Include app metadata if provided.
- Add lightweight IP-based rate limiting in Firestore so anonymous apps cannot spam.
- Throw `HttpsError` with stable codes (`invalid-argument`, `resource-exhausted`, `internal`).

Use `firebase-functions/v2/https`, `firebase-admin`, and `logger`.

## Firestore Rules

If feedback writes only happen through Admin SDK in Cloud Functions, users do not need direct Firestore write access. Use locked-down rules unless the app already has broader Firestore needs:

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

Merge with existing rules instead of overwriting unrelated rules.

## Swift Submitter

The app-side submitter should call the chosen region:

```swift
try await Functions.functions(region: "asia-northeast1")
    .httpsCallable("submitFeedback")
    .call(payload)
```

Do not log or store raw feedback message in Analytics. Logging category is fine.

## Validation

1. Run package install in `functions/`.
2. Run a syntax check: `node --check functions/index.js`.
3. Build the iOS app.
4. Deploy when ready:

```bash
firebase deploy --only functions:submitFeedback,firestore:rules
```

If `firebase` is not installed, use `npx firebase-tools deploy ...`.

## Troubleshooting

- `not found`: Swift region/name does not match the deployed callable, or it is not deployed.
- `permission-denied`: App Check or auth enforcement is enabled but the app is not providing the token.
- `resource-exhausted`: rate limit is working.
- `invalid-argument`: payload validation failed.
