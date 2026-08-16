import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("LaunchAtLogin toggle failed: \(error)")
        }
    }

    static func enable() {
        guard !isEnabled else { return }
        try? SMAppService.mainApp.register()
    }
}
