import SwiftUI
import AppKit

@main
struct StickyPalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: NoteWindowManager?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let manager = NoteWindowManager()
        self.windowManager = manager

        // Register system global hotkey (⌥ + Space)
        registerHotKey(manager: manager)

        // Set up clean menu bar item
        setupMenuBar(manager: manager)

        // Show existing notes or create first one
        manager.showAllNotes()

        // Enable launch at login on first run
        LaunchAtLogin.enable()
    }

    private func registerHotKey(manager: NoteWindowManager) {
        HotKeyManager.shared.register { [weak manager] in
            manager?.toggleVisibility()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar(manager: NoteWindowManager) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "note.text",
                accessibilityDescription: "StickyPal"
            )
        }

        let menu = NSMenu(title: "StickyPal")

        let newItem = NSMenuItem(
            title: "新建便签",
            action: #selector(newNote),
            keyEquivalent: "n"
        )
        newItem.target = self
        menu.addItem(newItem)

        let toggleItem = NSMenuItem(
            title: "显示 / 隐藏全部 (⌥Space)",
            action: #selector(toggleNotes),
            keyEquivalent: "h"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let launchItem = NSMenuItem(
            title: "开机自启",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 StickyPal",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func newNote() {
        windowManager?.createNewNote()
    }

    @objc private func toggleNotes() {
        windowManager?.toggleVisibility()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        LaunchAtLogin.toggle()
        sender.state = LaunchAtLogin.isEnabled ? .on : .off
    }
}

