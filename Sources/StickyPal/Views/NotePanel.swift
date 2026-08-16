import AppKit
import SwiftUI

final class NotePanel: NSPanel, NSWindowDelegate {

    var onDeleteRequested: (() -> Void)?
    var onCollapseToggled: ((Bool) -> Void)?
    var isCollapsed: Bool = false
    private var savedExpandedHeight: CGFloat = 180

    private let containerView = NSView()
    private let visualEffect = NSVisualEffectView()
    private let tintView = NSView()
    private let shaderView = MetalShaderBackgroundView()

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

        // Container view
        containerView.frame = contentRect
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 14
        containerView.layer?.cornerCurve = .continuous
        containerView.layer?.masksToBounds = true
        containerView.autoresizingMask = [.width, .height]

        // 1. Frosted glass background for classic mode
        visualEffect.frame = containerView.bounds
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.cornerCurve = .continuous
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]
        containerView.addSubview(visualEffect)

        // 2. Color tag tint layer
        tintView.frame = containerView.bounds
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = 14
        tintView.layer?.cornerCurve = .continuous
        tintView.autoresizingMask = [.width, .height]
        containerView.addSubview(tintView)

        // 3. Dynamic Metal shader background layer
        shaderView.frame = containerView.bounds
        containerView.addSubview(shaderView)

        contentView = containerView
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

    func applyTheme(_ theme: String) {
        if theme == "classic" {
            visualEffect.isHidden = false
            tintView.isHidden = false
        } else {
            visualEffect.isHidden = true
            tintView.isHidden = true
        }
        shaderView.applyTheme(theme)
    }

    func captureLiveFrame(size: CGSize) -> CGImage? {
        shaderView.captureCurrentFrame(size: size)
    }

    func applyOpacity(_ opacity: Double) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.alphaValue = CGFloat(opacity)
        }
    }

    func applyCollapse(_ collapsed: Bool, animated: Bool = true) {
        guard self.isCollapsed != collapsed else { return }
        self.isCollapsed = collapsed

        let curFrame = self.frame
        if collapsed {
            savedExpandedHeight = max(140, curFrame.height)
            let targetY = curFrame.origin.y + (curFrame.height - 36)
            let targetFrame = NSRect(x: curFrame.origin.x, y: targetY, width: curFrame.width, height: 36)
            self.minSize = NSSize(width: 180, height: 36)
            self.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: 36)
            self.setFrame(targetFrame, display: true, animate: animated)
        } else {
            let targetHeight = max(140, savedExpandedHeight)
            let targetY = curFrame.origin.y - (targetHeight - 36)
            let targetFrame = NSRect(x: curFrame.origin.x, y: targetY, width: curFrame.width, height: targetHeight)
            self.minSize = NSSize(width: 180, height: 140)
            self.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            self.setFrame(targetFrame, display: true, animate: animated)
        }
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown && event.clickCount == 2 {
            let point = event.locationInWindow
            // Double click in top bar area (above text or on header)
            if point.y >= self.frame.height - 36 {
                let newState = !isCollapsed
                applyCollapse(newState, animated: true)
                onCollapseToggled?(newState)
                return
            }
        }
        super.sendEvent(event)
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
