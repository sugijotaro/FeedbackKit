# FeedbackKit agent guidance

FeedbackKit is a UI-only Swift Package. Do not add Firebase, Vertex AI, GitHub credentials, App Store IDs, app identifiers, repository names, clipboard implementations, or product-specific values to the package itself.

When asked to integrate this repository into another SwiftUI app:

- use the latest stable semantic-version release through Swift Package Manager;
- inspect the current public API instead of assuming initializer signatures;
- use `.agents/skills/integrate-feedbackkit-complete/SKILL.md` when the requested scope is unclear or multiple capabilities may apply;
- ask how far the user wants to implement unless their request already makes the scope explicit;
- use `.agents/skills/integrate-feedbackkit-firebase/SKILL.md` only when Firestore storage is the requested scope;
- use `.agents/skills/automate-feedback-github-issues/SKILL.md` only when storage already exists or is also selected;
- use `.agents/skills/add-feedbackkit-app-store-review/SKILL.md` for post-submission or persistent App Store review links;
- implement host-specific Firebase, GitHub, App Store, and clipboard code in the host repository, never in FeedbackKit;
- run package tests, host-app builds, Functions builds, and available end-to-end checks before claiming completion;
- never claim deployment or device-only App Store behavior succeeded when credentials, metadata, or device access were unavailable.
