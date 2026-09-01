import AppKit
import Foundation

struct ClipboardItem: Identifiable {
    let id: UUID
    let content: Content
    let timestamp: Date
    var isPinned: Bool

    enum Content {
        case text(String)
        case image(NSImage)
    }

    init(content: Content, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
    }

    var displayText: String {
        switch content {
        case .text(let s): return s
        case .image:       return "[Şəkil]"
        }
    }

    var previewText: String {
        let t = displayText
        return t.count > 300 ? String(t.prefix(300)) + "…" : t
    }

    var isImage: Bool {
        if case .image = content { return true }
        return false
    }

    var nsImage: NSImage? {
        if case .image(let img) = content { return img }
        return nil
    }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(timestamp)
        if diff < 60     { return "İndicə" }
        if diff < 3600   { return "\(Int(diff / 60))d əvvəl" }
        if diff < 86400  { return "\(Int(diff / 3600))s əvvəl" }
        return "\(Int(diff / 86400))g əvvəl"
    }
}
