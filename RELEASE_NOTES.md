# FeedbackKit v1.2.1

This patch release strengthens the Firebase and GitHub automation Agent Skills so generated backend files do not remain untracked in host repositories.

## Highlights

- `integrate-feedbackkit-firebase` now requires precise `.gitignore` rules for Functions dependencies, TypeScript output, emulator artifacts, and Firebase debug logs.
- `automate-feedback-github-issues` applies the same repository-hygiene checks when adding AI triage and GitHub Issue automation.
- `integrate-feedbackkit-complete` carries the requirement across all Firebase-backed implementation scopes.
- Typical root-level patterns are documented:

```gitignore
firebase/functions/node_modules/
firebase/functions/lib/
firebase-debug.log*
firestore-debug.log*
ui-debug.log*
```

- Nested Functions repositories may use relative `node_modules/` and `lib/` rules instead.
- Skills explicitly preserve source files, Firebase configuration, Firestore rules, and package-manager lockfiles.
- Agents must inspect `git status --short --branch --untracked-files=all` after dependency installation and builds.
- Agents must not use `git clean`, ignore an entire Firebase directory, or delete unknown files without inspection.
- CI verifies that all Firebase-related Skills contain the generated-file guidance.

FeedbackKit itself remains a reusable, UI-only SwiftUI package. Firebase, Vertex AI, GitHub, App Store metadata, and product-specific values remain in the host application repository.
