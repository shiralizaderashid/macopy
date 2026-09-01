import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var manager: ClipboardManager
    @ObservedObject var state: PanelState
    var onPaste:   (ClipboardItem) -> Void
    var onDismiss: () -> Void

    var filtered: [ClipboardItem] {
        let q = state.searchText
        guard !q.isEmpty else { return manager.items }
        return manager.items.filter { $0.displayText.localizedCaseInsensitiveContains(q) }
    }

    // Clamp so a deletion can never leave selectedIndex out of bounds
    var safeSelected: Int {
        guard !filtered.isEmpty else { return 0 }
        return min(state.selectedIndex, filtered.count - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            itemList
            Divider()
            footer
        }
        .frame(width: 440, height: 540)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 15, weight: .medium))
            Text("Clipboard History")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            if manager.items.contains(where: { !$0.isPinned }) {
                Button { manager.clearAll() } label: {
                    Text("Sil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.system(size: 13))
            TextField("Axtar...", text: $state.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onChange(of: state.searchText) { _ in
                    state.selectedIndex = 0
                }
                .onSubmit {
                    if !filtered.isEmpty { onPaste(filtered[safeSelected]) }
                }
            if !state.searchText.isEmpty {
                Button { state.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Item list

    @ViewBuilder
    private var itemList: some View {
        if filtered.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text(state.searchText.isEmpty ? "Clipboard boşdur" : "Nəticə tapılmadı")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    // VStack (not Lazy) so SwiftUI tracks items by UUID without
                    // position-based recycling. Max 50 items — performance is fine.
                    VStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, item in
                            ItemRow(
                                item: item,
                                index: idx,
                                isSelected: idx == safeSelected,
                                onTap: { onPaste(item) },
                                onPin: { manager.togglePin(item) },
                                onDelete: {
                                    manager.delete(item)
                                    if idx <= state.selectedIndex {
                                        state.selectedIndex = max(0, state.selectedIndex - 1)
                                    }
                                }
                            )
                            .id(item.id)   // UUID — consistent with ForEach id:, no index conflict
                            if idx < filtered.count - 1 {
                                Divider().padding(.leading, 46)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: safeSelected) { newVal in
                    guard filtered.indices.contains(newVal) else { return }
                    withAnimation(.easeInOut(duration: 0.12)) {
                        proxy.scrollTo(filtered[newVal].id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            BadgeHint("↑↓", label: "Naviqasiya")
            BadgeHint("↵",  label: "Yapışdır")
            BadgeHint("⌘⌫", label: "Sil")
            BadgeHint("⎋",  label: "Bağla")
            Spacer()
            Text("\(filtered.count) element")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}

// MARK: - Item Row

struct ItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    var onTap: () -> Void
    var onPin: () -> Void
    var onDelete: () -> Void

    @State private var hovered = false

    var body: some View {
        ZStack(alignment: .trailing) {

            // ── Bottom layer: paste tap area ─────────────────────────────
            Button(action: onTap) {
                HStack(spacing: 0) {
                    // Number badge
                    if index < 9 {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 22)
                    } else {
                        Color.clear.frame(width: 22)
                    }

                    // Image thumbnail
                    if item.isImage, let img = item.nsImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .cornerRadius(5)
                            .padding(.trailing, 8)
                    } else {
                        Color.clear.frame(width: 4)
                    }

                    // Text preview + timestamp
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.previewText)
                            .font(.system(size: 12.5))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(item.timeAgo)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    // Trailing spacer — keeps text from sliding under action buttons
                    Color.clear.frame(width: (hovered || isSelected) ? 62 : (item.isPinned ? 18 : 4))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // ── Top layer: action buttons (sit above the tap area) ────────
            HStack(spacing: 2) {
                if item.isPinned && !(hovered || isSelected) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
                if hovered || isSelected {
                    IconButton(systemName: item.isPinned ? "pin.slash" : "pin",
                               color: .secondary, action: onPin)
                    IconButton(systemName: "trash", color: .red, action: onDelete)
                }
            }
            .padding(.trailing, 10)
            .animation(.easeInOut(duration: 0.1), value: hovered)
        }
        .background(
            isSelected
                ? Color.accentColor.opacity(0.18)
                : (hovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Helpers

struct BadgeHint: View {
    let key: String
    let label: String
    init(_ key: String, label: String) { self.key = key; self.label = label }
    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 3))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct IconButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .padding(5)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}
