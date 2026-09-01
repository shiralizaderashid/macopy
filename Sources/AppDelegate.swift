import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let manager  = ClipboardManager()
    private var panelCtrl: HistoryPanelController!
    private var hotkey:    HotkeyManager!
    private var settingsCtrl: SettingsWindowController!

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory)

        manager.start()
        panelCtrl = HistoryPanelController(manager: manager)

        // Load saved hotkey config (falls back to ⌘⇧V if none saved)
        hotkey = HotkeyManager(config: .load()) { [weak self] in
            DispatchQueue.main.async { self?.panelCtrl.toggle() }
        }
        hotkey.register()

        settingsCtrl = SettingsWindowController(hotkeyManager: hotkey)

        setupStatusItem()

        // Request accessibility permission once at launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.checkAccessibility()
        }
    }

    // MARK: - Accessibility

    private func checkAccessibility() {
        guard !AXIsProcessTrusted() else { return }

        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            Macopy needs Accessibility access for auto-paste.

            1. Click "Open Settings"
            2. Find Macopy in the list and enable it
            3. Click "Restart" when done

            (Without permission, items are still copied to the clipboard — paste with ⌘V manually.)
            """
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Later")

        NSApp.activate(ignoringOtherApps: true)
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        case .alertSecondButtonReturn:
            relaunch()
        default:
            break
        }
    }

    private func relaunch() {
        let url = Bundle.main.bundleURL
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
    }

    // MARK: - Status bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let btn = statusItem?.button {
            let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            btn.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                accessibilityDescription: "Clipboard History")?
                .withSymbolConfiguration(cfg)
        }

        rebuildMenu()
    }

    // Rebuild menu so the shortcut label stays current after settings change.
    func rebuildMenu() {
        let menu = NSMenu()
        let shortcut = hotkey?.config.displayString ?? "⌘⇧V"
        menu.addItem(withTitle: "Show History  (\(shortcut))",
                     action: #selector(showPanel), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…",
                     action: #selector(showSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Clear History",
                     action: #selector(clearHistory), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit",
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func showPanel()    { panelCtrl.toggle() }
    @objc private func clearHistory() { manager.clearAll() }
    @objc private func showSettings() {
        settingsCtrl.showWindow()
        // After the window closes, rebuild the menu label with the new shortcut.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildMenu()
        }
    }
}
