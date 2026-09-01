import Carbon
import AppKit

class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private(set) var config: HotkeyConfig
    private let onFire: () -> Void

    init(config: HotkeyConfig = .load(), onFire: @escaping () -> Void) {
        self.config = config
        self.onFire = onFire
    }

    // MARK: - Register / Unregister

    func register() {
        // Install the Carbon event handler once; keep it for the app lifetime.
        if eventHandlerRef == nil {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind:  OSType(kEventHotKeyPressed))
            let ptr = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, _, userData -> OSStatus in
                    guard let p = userData else { return noErr }
                    Unmanaged<HotkeyManager>.fromOpaque(p).takeUnretainedValue().onFire()
                    return noErr
                },
                1, &spec, ptr, &eventHandlerRef
            )
        }

        // (Re-)register the hotkey binding.
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }

        var hkID = EventHotKeyID()
        hkID.signature = fourCC("MAKY")
        hkID.id = 1

        RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
    }

    func update(config: HotkeyConfig) {
        self.config = config
        config.save()
        register()
    }

    deinit {
        if let ref = hotKeyRef      { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
    }
}

private func fourCC(_ s: String) -> FourCharCode {
    s.utf16.prefix(4).reduce(0) { ($0 << 8) | FourCharCode($1) }
}
