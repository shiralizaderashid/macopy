import AppKit
import SwiftUI
import Carbon

// Shared reactive state between the controller and the SwiftUI view.
// Controller writes → SwiftUI re-renders automatically. No refreshView() needed.
class PanelState: ObservableObject {
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = ""
}

// NSPanel subclass so makeKeyAndOrderFront actually grants key status
// (borderless windows return false from canBecomeKey by default).
class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool  { true }
    override var canBecomeMain: Bool { false }
}

class HistoryPanelController {
    private var panel: HistoryPanel?
    private let manager: ClipboardManager
    let state = PanelState()

    private var previousApp: NSRunningApplication?
    private var keyMonitor: Any?
    private var resignKeyObserver: NSObjectProtocol?
    private let positionKey = "macopy_panel_origin"

    init(manager: ClipboardManager) {
        self.manager = manager
    }

    // MARK: - Toggle / Show / Hide

    func toggle() {
        if let p = panel, p.isVisible { hide() } else { show() }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication

        // Reset selection & search on every open
        state.selectedIndex = 0
        state.searchText = ""

        if panel == nil { buildPanel() }
        positionPanel()
        panel?.makeKeyAndOrderFront(nil)
        installKeyMonitor()

        // Click-outside: when the panel loses key status (user clicked elsewhere)
        // the window posts didResignKeyNotification — cleanest, no coordinate math.
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }
    }

    func hide() {
        // Save position before hiding so next open restores it
        if let p = panel {
            savePanelOrigin(p.frame.origin)
        }
        // Remove observer BEFORE orderOut so we don't re-enter hide()
        if let obs = resignKeyObserver {
            NotificationCenter.default.removeObserver(obs)
            resignKeyObserver = nil
        }
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    // MARK: - Panel (built once, reused forever)

    private func buildPanel() {
        let root = HistoryView(
            manager: manager,
            state: state,
            onPaste:   { [weak self] item in self?.paste(item) },
            onDismiss: { [weak self] in self?.hide() }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(x: 0, y: 0, width: 440, height: 540)

        let p = HistoryPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 540),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = true
        p.contentView = hosting
        self.panel = p
    }

    private func positionPanel() {
        guard let panel = panel else { return }

        // Restore saved position if it still fits on a screen
        if let saved = loadPanelOrigin() {
            let panelRect = NSRect(origin: saved, size: panel.frame.size)
            let onScreen = NSScreen.screens.contains {
                $0.visibleFrame.intersects(panelRect)
            }
            if onScreen {
                panel.setFrameOrigin(saved)
                return
            }
        }

        // Default: center on main screen
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: sf.midX - panel.frame.width  / 2,
            y: sf.midY - panel.frame.height / 2
        ))
    }

    private func savePanelOrigin(_ origin: NSPoint) {
        UserDefaults.standard.set(
            ["x": origin.x, "y": origin.y],
            forKey: positionKey
        )
    }

    private func loadPanelOrigin() -> NSPoint? {
        guard let d = UserDefaults.standard.dictionary(forKey: positionKey),
              let x = d["x"] as? Double,
              let y = d["y"] as? Double else { return nil }
        return NSPoint(x: x, y: y)
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel?.isVisible == true else { return event }
            return self.handleKey(event)
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        let list = currentFiltered()
        switch Int(event.keyCode) {

        case kVK_Escape:
            hide()
            return nil

        case kVK_UpArrow:
            if state.selectedIndex > 0 { state.selectedIndex -= 1 }
            return nil

        case kVK_DownArrow:
            if state.selectedIndex < list.count - 1 { state.selectedIndex += 1 }
            return nil

        case kVK_Return:
            if !list.isEmpty { paste(list[min(state.selectedIndex, list.count - 1)]) }
            return nil

        case kVK_Delete where event.modifierFlags.contains(.command):
            if !list.isEmpty {
                let idx = min(state.selectedIndex, list.count - 1)
                manager.delete(list[idx])
                if idx <= state.selectedIndex {
                    state.selectedIndex = max(0, state.selectedIndex - 1)
                }
            }
            return nil

        case kVK_ANSI_1...kVK_ANSI_9:
            let d = digitFromKeyCode(Int(event.keyCode))
            if d > 0, d <= list.count { paste(list[d - 1]) }
            return nil

        default:
            return event
        }
    }

    // MARK: - Paste

    private func paste(_ item: ClipboardItem) {
        manager.copyToPasteboard(item)
        let target = previousApp
        hide()
        target?.activate(options: .activateIgnoringOtherApps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { self.simulatePaste() }
    }

    private func simulatePaste() {
        guard AXIsProcessTrusted() else {
            // Item is already in clipboard; user can ⌘V manually.
            // Open Settings silently so user can grant without another dialog storm.
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
            return
        }
        let src  = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Helpers

    private func currentFiltered() -> [ClipboardItem] {
        let q = state.searchText
        guard !q.isEmpty else { return manager.items }
        return manager.items.filter { $0.displayText.localizedCaseInsensitiveContains(q) }
    }

    private func digitFromKeyCode(_ kc: Int) -> Int {
        [kVK_ANSI_1: 1, kVK_ANSI_2: 2, kVK_ANSI_3: 3, kVK_ANSI_4: 4,
         kVK_ANSI_5: 5, kVK_ANSI_6: 6, kVK_ANSI_7: 7, kVK_ANSI_8: 8, kVK_ANSI_9: 9][kc] ?? 0
    }
}
