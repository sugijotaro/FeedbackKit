#if os(iOS)
import SwiftUI
import UIKit

struct ShakeGestureDetector: UIViewControllerRepresentable {
    let isEnabled: Bool
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeGestureViewController {
        ShakeGestureViewController(isEnabled: isEnabled, onShake: onShake)
    }

    func updateUIViewController(
        _ viewController: ShakeGestureViewController,
        context: Context
    ) {
        viewController.update(isEnabled: isEnabled, onShake: onShake)
    }
}

final class ShakeGestureViewController: UIViewController {
    private var isShakeEnabled: Bool
    private var onShake: () -> Void

    init(isEnabled: Bool, onShake: @escaping () -> Void) {
        isShakeEnabled = isEnabled
        self.onShake = onShake
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var canBecomeFirstResponder: Bool {
        isShakeEnabled
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard isShakeEnabled, motion == .motionShake else {
            super.motionEnded(motion, with: event)
            return
        }

        onShake()
    }

    func update(isEnabled: Bool, onShake: @escaping () -> Void) {
        isShakeEnabled = isEnabled
        self.onShake = onShake
        updateFirstResponder()
    }

    private func updateFirstResponder() {
        if isShakeEnabled {
            becomeFirstResponder()
        } else {
            resignFirstResponder()
        }
    }
}
#endif
