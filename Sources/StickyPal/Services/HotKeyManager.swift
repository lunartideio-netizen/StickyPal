import Carbon
import AppKit

@MainActor
final class HotKeyManager: Sendable {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var localMonitor: Any?

    nonisolated(unsafe) static var toggleCallback: (() -> Void)?

    private init() {}

    // MARK: - Register Hotkey

    func register(onToggle: @escaping () -> Void) {
        HotKeyManager.toggleCallback = onToggle
        unregister()

        // 1. Carbon Event Dispatcher (Apple's native system-wide hotkey, works globally)
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, inEvent, _) -> OSStatus in
                DispatchQueue.main.async {
                    HotKeyManager.toggleCallback?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x5354_4B50), // "STKP"
            id: 1
        )

        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("[StickyPal] Carbon RegisterEventHotKey status: (status)")
        }

        // 2. Local monitor as backup when sticky note or app is in focus
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .option && event.keyCode == UInt16(kVK_Space) {
                DispatchQueue.main.async {
                    HotKeyManager.toggleCallback?()
                }
                return nil
            }
            return event
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

