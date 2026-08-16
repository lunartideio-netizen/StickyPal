import AppKit
import SwiftUI

/// Custom NSTextView that embeds a custom context menu and seamless transparent background.
final class CustomNoteTextView: NSTextView {
    var onContextMenu: (() -> NSMenu?)?
    var onTextChange: ((String) -> Void)?

    override func menu(for event: NSEvent) -> NSMenu? {
        if let customMenu = onContextMenu?() {
            return customMenu
        }
        return super.menu(for: event)
    }

    override func didChangeText() {
        super.didChangeText()
        onTextChange?(string)
    }
}

/// AppKit NSViewRepresentable wrapper for the note text editor.
struct NoteTextEditorView: NSViewRepresentable {
    @Binding var text: String
    let onContextMenu: () -> NSMenu?
    let onTextChange: (String) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = CustomNoteTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.allowsUndo = true

        // Leave top space for traffic lights (~28pt) and comfortable side margins
        textView.textContainerInset = NSSize(width: 14, height: 12)
        scrollView.contentInsets = NSEdgeInsets(top: 26, left: 0, bottom: 8, right: 0)

        textView.string = text
        textView.onContextMenu = onContextMenu
        textView.onTextChange = onTextChange

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = context.coordinator.textView, textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.setSelectedRanges(selectedRanges, affinity: .upstream, stillSelecting: false)
        }
        context.coordinator.textView?.onContextMenu = onContextMenu
        context.coordinator.textView?.onTextChange = onTextChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var textView: CustomNoteTextView?
    }
}

