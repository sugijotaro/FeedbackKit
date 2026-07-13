# FeedbackKit

FeedbackKit is a SwiftUI package for showing an in-app feedback sheet. It provides only the UI and passes submitted feedback back to the host app.

## Installation

Add `Packages/FeedbackKit` as a local Swift Package dependency, then add the `FeedbackKit` library to your app target.

## Basic Usage

```swift
import SwiftUI
import FeedbackKit

struct SettingsView: View {
    @State private var isPresented = false

    var body: some View {
        Button("ご意見・ご要望") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            FeedbackSheet(appName: "ColorCam") { feedback in
                print(feedback.category)
                print(feedback.message)
            }
        }
    }
}
```

## Async Submission

```swift
FeedbackSheet(appName: "ColorCam") { feedback in
    try await submitFeedback(feedback)
}
```

Firebase, API calls, and other network handling should be implemented by the host app.
