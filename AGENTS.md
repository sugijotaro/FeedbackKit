# FeedbackKit agent guidance

FeedbackKit is a UI-only Swift Package. Do not add Firebase, Vertex AI, GitHub credentials, app identifiers, repository names, or product-specific values to the package itself.

When asked to integrate this repository into another SwiftUI app:

- use the latest stable semantic-version release through Swift Package Manager;
- inspect the current public API instead of assuming initializer signatures;
- use `.agents/skills/integrate-feedbackkit-complete/SKILL.md` for an end-to-end implementation;
- use `.agents/skills/integrate-feedbackkit-firebase/SKILL.md` only when Firestore storage is the requested scope;
- use `.agents/skills/automate-feedback-github-issues/SKILL.md` only when storage already exists;
- implement host-specific Firebase and GitHub code in the host repository, never in FeedbackKit;
- run package tests, host-app builds, Functions builds, and available end-to-end checks before claiming completion;
- never claim deployment succeeded when credentials or console access were unavailable.
