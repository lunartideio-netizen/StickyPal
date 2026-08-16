import AppKit
import SwiftUI

final class NotePanel: NSPanel, NSWindowDelegate {

    var onDeleteRequested: (() -> Void)?
    private let tintView = NSView()

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .nonactivatingPanel,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        // Floating level to stay above regular app windows
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Modern transparent titlebar showing native traffic lights
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // Keep panel responsive
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false

        // Minimum and reasonable default sizes
        minSize = NSSize(width: 180, height: 140)

        // Frosted glass background with smooth Apple continuous rounded corners
        let visualEffect = NSVisualEffectView(frame: contentRect)
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.cornerCurve = .continuous
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        // Color tag tint layer
        tintView.frame = visualEffect.bounds
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = 14
        tintView.layer?.cornerCurve = .continuous
        tintView.autoresizingMask = [.width, .height]
        visualEffect.addSubview(tintView)

        contentView = visualEffect
        delegate = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func applyColorTag(_ tag: String) {
        let targetColor = NoteColors.color(for: tag)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            tintView.layer?.backgroundColor = targetColor.cgColor
        }
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Red traffic light button clicked: delete this note
        onDeleteRequested?()
        return false // We handle window closing / removal in NoteWindowManager
    }

    func forceClose() {
        super.close()
    }
}
