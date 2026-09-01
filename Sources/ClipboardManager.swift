import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private var timer: Timer?
    private var lastChangeCount = 0
    private let maxItems = 50
    private let storageKey = "macopy_history"

    func start() {
        loadFromDisk()
        lastChangeCount = NSPasteboard.general.changeCount
        let t = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if let str = pb.string(forType: .string), !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addItem(ClipboardItem(content: .text(str)))
        } else if let img = NSImage(pasteboard: pb) {
            addItem(ClipboardItem(content: .image(img)))
        }
    }

    private func addItem(_ new: ClipboardItem) {
        if case .text(let newText) = new.content {
            // Already at top → skip entirely
            if let top = items.first, case .text(let topText) = top.content, topText == newText {
                return
            }
            // Exists lower in list → remove so we move it to top
            items.removeAll {
                if case .text(let t) = $0.content { return t == newText }
                return false
            }
        }
        items.insert(new, at: 0)

        let pinned   = items.filter { $0.isPinned }
        var unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems { unpinned = Array(unpinned.prefix(maxItems)) }
        items = pinned + unpinned

        saveToDisk()
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let s):
            pb.setString(s, forType: .string)
        case .image(let img):
            pb.writeObjects([img])
        }
        lastChangeCount = pb.changeCount
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        saveToDisk()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func clearAll() {
        items.removeAll { !$0.isPinned }
        saveToDisk()
    }

    // MARK: - Persistence (text only)

    private func saveToDisk() {
        let payload: [[String: Any]] = items.compactMap { item in
            guard case .text(let t) = item.content else { return nil }
            return ["t": t, "ts": item.timestamp.timeIntervalSince1970, "pin": item.isPinned]
        }
        UserDefaults.standard.set(payload, forKey: storageKey)
    }

    private func loadFromDisk() {
        guard let saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] else { return }
        items = saved.compactMap { d in
            guard let t = d["t"] as? String,
                  let ts = d["ts"] as? Double else { return nil }
            return ClipboardItem(
                content: .text(t),
                timestamp: Date(timeIntervalSince1970: ts),
                isPinned: d["pin"] as? Bool ?? false
            )
        }
    }
}
