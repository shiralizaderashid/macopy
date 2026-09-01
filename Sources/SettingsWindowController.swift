import AppKit
import SwiftUI
import Carbon

// Observable state shared between the controller and SwiftUI view.
class SettingsWindowController: ObservableObject {
    @Published var isRecording  = false
    @Published var pendingConfig: HotkeyConfig

    private weak var hotkeyManager: HotkeyManager?
    private var window: NSWindow?
    private var keyMonitor: Any?

    init(hotkeyManager: HotkeyManager) {
        self.hotkeyManager   = hotkeyManager
        self.pendingConfig   = hotkeyManager.config
    }

    // MARK: - Window

    func showWindow() {
        if let w = window, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Reset to current saved config each time the window opens
        pendingConfig = hotkeyManager?.config ?? .default

        let view    = SettingsView(controller: self)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 400, height: 190)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 190),
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        w.title = "Macopy — Ayarlar"
        w.contentView = hosting
        w.isReleasedWhenClosed = false
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }

    // MARK: - Recording

    func startRecording() {
        hotkeyManager?.unregister()     // Prevent triggering panel while recording
        isRecording = true
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handleRecordedKey(event)
        }
    }

    func stopRecording() {
        isRecording = false
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        hotkeyManager?.register()      // Restore hotkey
    }

    private func handleRecordedKey(_ event: NSEvent) -> NSEvent? {
        // Escape cancels recording
        if Int(event.keyCode) == kVK_Escape { stopRecording(); return nil }

        let mods = event.modifierFlags
        guard !mods.intersection([.command, .option, .control, .shift]).isEmpty else {
            return nil  // Require at least one modifier
        }

        var carbonMods: UInt32 = 0
        if mods.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if mods.contains(.shift)   { carbonMods |= UInt32(shiftKey) }
        if mods.contains(.option)  { carbonMods |= UInt32(optionKey) }
        if mods.contains(.control) { carbonMods |= UInt32(controlKey) }

        pendingConfig = HotkeyConfig(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
        stopRecording()
        return nil
    }

    // MARK: - Save / Cancel

    func save() {
        hotkeyManager?.update(config: pendingConfig)
        window?.close()
    }

    func cancel() {
        if isRecording { stopRecording() }
        pendingConfig = hotkeyManager?.config ?? .default
        window?.close()
    }
}

// MARK: - SwiftUI View

struct SettingsView: View {
    @ObservedObject var controller: SettingsWindowController

    var body: some View {
        VStack(spacing: 24) {

            // Title
            Text("Klaviatura Qısayolu")
                .font(.headline)

            // Shortcut recorder
            VStack(spacing: 10) {
                HStack(spacing: 14) {
                    Text("Qısayol:")
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .trailing)

                    // Pill button — click to start/stop recording
                    Button {
                        if controller.isRecording {
                            controller.stopRecording()
                        } else {
                            controller.startRecording()
                        }
                    } label: {
                        Text(controller.isRecording ? "Basın…" : controller.pendingConfig.displayString)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(controller.isRecording ? Color.red : Color.primary)
                            .frame(minWidth: 110)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        controller.isRecording ? Color.red : Color.accentColor,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    if !controller.isRecording {
                        Button("Sıfırla") {
                            controller.pendingConfig = .default
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }
                }

                if controller.isRecording {
                    Text("Modifier (⌘ ⇧ ⌥ ⌃) + istənilən düymə • Escape ilə ləğv et")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Buttons
            HStack(spacing: 12) {
                Button("Ləğv Et") { controller.cancel() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])

                Button("Saxla") { controller.save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(controller.isRecording)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(28)
        .frame(width: 400)
    }
}
