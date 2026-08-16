import SwiftUI

struct NoteContentView: View {
    let noteID: UUID
    let store: NoteStore
    let onContextMenu: () -> NSMenu?

    @State private var content: String = ""
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        NoteTextEditorView(
            text: $content,
            onContextMenu: onContextMenu,
            onTextChange: { newText in
                debouncedSave(newText)
            }
        )
        .onAppear {
            content = store.note(for: noteID)?.content ?? ""
        }
    }

    private func debouncedSave(_ newValue: String) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                store.update(id: noteID) { n in
                    n.content = newValue
                }
            }
        }
    }
}

