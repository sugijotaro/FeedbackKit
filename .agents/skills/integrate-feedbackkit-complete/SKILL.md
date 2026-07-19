---
name: integrate-feedbackkit-complete
description: Orchestrate FeedbackKit integration into an existing SwiftUI app. First clarify how far the user wants to go, then add the selected combination of the Swift Package and sheet UI, Firebase and Firestore storage, Gemini triage on Vertex AI, GitHub Issue automation, and an optional App Store review handoff. Use when the user provides the FeedbackKit repository URL or asks what FeedbackKit can implement.
metadata:
  short-description: Choose and add FeedbackKit features
---

# Integrate FeedbackKit

This is the scope-selection and orchestration Skill for FeedbackKit. Do not assume that every user wants Firebase, AI automation, GitHub Issues, or an App Store review handoff.

## Source

Use the latest stable semantic-version release of:

```text
https://github.com/sugijotaro/FeedbackKit
```

Read the current public API before editing the host app. Add FeedbackKit through Swift Package Manager; do not copy its source files into the app.

## Ask the implementation scope first

Before changing the host repository, ask the user how far to implement unless their request already makes the scope explicit.

Use a compact question equivalent to:

```text
FeedbackKitでは次の範囲を実装できます。どこまで進めますか？

基本範囲
1. フォームUIのみ
2. UI + Firebase / Firestore保存
3. UI + 保存 + Gemini分析 + GitHub Issue自動作成

追加オプション
4. 送信後のApp Storeレビュー導線
5. 設定画面の常設レビューリンク

「全部」でも大丈夫です。
```

The base scopes are cumulative. The App Store review choices are optional additions to any base scope.

Do not ask this question when the user already says, for example, "UIだけ", "Firestoreまで", "GitHub Issueまで", "レビュー導線も", or "全部". Infer the selected scope from that request and proceed.

Do not begin implementation while the scope remains materially ambiguous.

## Available capabilities

### A. Feedback form UI

- Swift Package Manager integration;
- FeedbackKit product linked to the correct target;
- settings, help, support, or account entry point;
- localized feedback form;
- async host-owned submission closure;
- loading, error, and completion states.

### B. Firebase and Firestore storage

Read and apply:

```text
.agents/skills/integrate-feedbackkit-firebase/SKILL.md
```

This adds:

- a host-app `FirebaseFunctions` submitter;
- callable `submitFeedback`;
- validation and anonymous rate limiting without requiring App Check;
- server-only Firestore storage;
- `feedback/{feedbackId}` documents with `status: "pending"`;
- safe Firestore Rules integration without replacing unrelated rules;
- precise `.gitignore` entries for Functions dependencies, compiler output, emulator artifacts, and Firebase debug logs.

### C. Gemini triage and GitHub Issue automation

Read and apply:

```text
.agents/skills/automate-feedback-github-issues/SKILL.md
```

This adds:

- a Firestore create trigger on Cloud Functions 2nd gen;
- Gemini analysis through Vertex AI and runtime Application Default Credentials;
- no Gemini API key or committed service-account JSON;
- structured classification, priority, confidence, sensitive-data checks, and label allowlists;
- semantic duplicate locks and feedback-specific GitHub operation records;
- GitHub App authentication;
- staged rollout before automatic Issue creation is enabled.

This scope requires Firebase storage. If the user selects AI and GitHub automation, include scope B even when they did not name it separately.

### D. App Store review handoff

Read and apply:

```text
.agents/skills/add-feedbackkit-app-store-review/SKILL.md
```

This can add:

- an optional button after successful feedback submission;
- passing the submitted `Feedback` value to host-owned review code;
- copying the message only after an explicit tap;
- opening the App Store product page with `action=write-review`;
- an optional persistent Settings review link.

The App Store ID, clipboard code, and product URL remain in the host app. Do not implement sentiment-based review gating.

## Inspect the host repository

After scope is selected, determine only what the selected features need:

- SwiftUI target, platforms, minimum OS, and Xcode project conventions;
- settings/help/support location;
- existing localization, navigation, and dependency-injection patterns;
- existing Firebase project and Functions conventions when storage is selected;
- applicable root and nested `.gitignore` files when Firebase or Node tooling is selected;
- authoritative Firestore rules when storage is selected;
- target GitHub repository and available authentication when automation is selected;
- numeric App Store ID and clipboard abstraction when review features are selected;
- available Firebase CLI, gcloud, GitHub, and App Store metadata access.

Preserve the existing architecture. Do not move unrelated files or replace unrelated security rules.

## Implement selected scope

### UI-only example

```swift
FeedbackSheet { feedback in
    localFeedbackHandler(feedback)
}
```

The host app must still decide what the closure does. Do not silently discard submissions unless the user explicitly requested a UI prototype.

### Firebase submission example

```swift
FeedbackSheet { feedback in
    try await feedbackSubmissionService.submit(feedback)
}
```

### Firebase plus App Store review example

```swift
FeedbackSheet(
    onSubmit: { feedback in
        try await feedbackSubmissionService.submit(feedback)
    },
    onWriteAppStoreReview: { feedback in
        reviewHandoff.open(feedback)
    }
)
```

Use the host app's tint, localization, navigation, error, analytics, and dependency-injection conventions. Keep FeedbackKit itself UI-only.

## Generated-file hygiene for Firebase scopes

When Firebase or GitHub automation is selected, update the host repository's existing `.gitignore` before running package installation or builds. Use repository-relative patterns and avoid duplicates. A common layout requires:

```gitignore
firebase/functions/node_modules/
firebase/functions/lib/
firebase-debug.log*
firestore-debug.log*
ui-debug.log*
```

A nested `firebase/functions/.gitignore` may instead use `node_modules/` and `lib/`. Preserve and commit package-manager lockfiles, TypeScript source, `package.json`, `tsconfig.json`, Firebase configuration, and Firestore rules. Never solve generated-file noise by ignoring an entire `firebase/` or `functions/` directory.

After every dependency install and build, inspect:

```bash
git status --short --branch --untracked-files=all
```

Do not finish while generated dependencies, compiler output, emulator data, or debug logs remain untracked. Do not use `git clean` or delete unknown files without inspection.

## Validate according to selected scope

Always:

- resolve Swift packages;
- build the affected host-app target;
- validate changed String Catalogs;
- verify the sheet is reachable;
- verify failed submissions preserve user input.

When Firebase is selected:

- run Functions dependency installation, type-check, tests when present, and build;
- test blank, oversized, malformed, and rapid-repeat payloads;
- verify client Firestore access remains closed;
- verify unrelated Firestore rules remain intact;
- verify raw feedback and request addresses are not logged;
- verify generated dependency and build paths are ignored and the worktree contains only intentional source, configuration, and lockfile changes.

When Gemini and GitHub are selected:

- test sensitive, ambiguous, praise, actionable, and duplicate submissions;
- verify retries cannot create a second Issue;
- keep automatic creation disabled until triage quality is reviewed;
- perform an end-to-end controlled Issue test only after credentials are configured.

When App Store review features are selected:

- verify the CTA appears only after successful submission;
- verify copying occurs only after an explicit tap;
- verify the numeric App Store ID and `action=write-review` URL;
- verify no feedback body is logged;
- test App Store opening on a real device when possible.

Add or update CI so the chosen integration remains buildable.

## Deploy only when authorized

When the selected scope requires deployment and authenticated tools are available, perform the deployment and controlled end-to-end tests.

Do not claim deployment or end-to-end completion unless those operations actually succeeded. If credentials or console permissions are unavailable, finish all repository changes and local/CI validation, then report only the exact external actions still blocked.

Never replace unavailable credentials with hard-coded keys, personal access tokens, or committed secret files.

## Definition of done

The task is complete when every selected capability works and is verified.

For all scopes:

1. FeedbackKit is linked to the correct target.
2. The intended entry point presents the sheet.
3. The host app builds.
4. No app-specific value or secret was added to FeedbackKit itself.

Additionally require the relevant conditions:

- Firebase selected: valid feedback reaches the callable and is stored in Firestore, and generated Functions files remain ignored.
- Gemini/GitHub selected: structured triage runs and one controlled actionable report creates exactly one Issue after automation is enabled.
- Review handoff selected: the completion CTA receives the submitted feedback, copies only on tap when requested, and opens the correct App Store write-review URL.
- Persistent review link selected: it opens the App Store review page without copying stale feedback.

Report the selected scope, changed files, deployed resources, tests performed, final `git status`, and any credential-bound action that could not be completed.
