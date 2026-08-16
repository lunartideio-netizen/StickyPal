import SwiftUI

struct NoteContentView: View {
    let noteID: UUID
    let store: NoteStore
    let onContextMenu: () -> NSMenu?

    @State private var saveTask: Task<Void, Never>?

    private var currentNote: StickyNote? {
        store.note(for: noteID)
    }

    var body: some View {
        NoteTextEditorView(
            plainContent: currentNote?.content ?? "",
            rtfdDataBase64: currentNote?.rtfdDataBase64,
            onContextMenu: onContextMenu,
            onContentChange: { plain, rtfd in
                debouncedSave(plain: plain, rtfd: rtfd)
            }
        )
    }

    private func debouncedSave(plain: String, rtfd: String?) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                store.update(id: noteID) { n in
                    n.content = plain
                    n.rtfdDataBase64 = rtfd
                }
            }
        }
    }
}
