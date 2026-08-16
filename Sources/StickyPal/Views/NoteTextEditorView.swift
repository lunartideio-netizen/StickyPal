import AppKit
import SwiftUI

/// Custom NSTextView that supports text editing, image attachments, drag & drop, and context menus.
final class CustomNoteTextView: NSTextView {
    var onContextMenu: (() -> NSMenu?)?
    var onContentChange: ((String, String?) -> Void)?

    override func menu(for event: NSEvent) -> NSMenu? {
        if let customMenu = onContextMenu?() {
            return customMenu
        }
        return super.menu(for: event)
    }

    override func didChangeText() {
        super.didChangeText()
        notifyContentChange()
    }

    func notifyContentChange() {
        let plain = string
        var rtfdBase64: String? = nil

        let attrStr = attributedString()
        if attrStr.length > 0 {
            if let rtfdData = attrStr.rtfd(from: NSRange(location: 0, length: attrStr.length)) {
                rtfdBase64 = rtfdData.base64EncodedString()
            }
        }

        onContentChange?(plain, rtfdBase64)
    }

    // MARK: - Drag and Drop Support for Images

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pboard = sender.draggingPasteboard
        if pboard.canReadObject(forClasses: [NSImage.self, NSURL.self], options: nil) {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard

        // Check for image files dragged from Finder
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstUrl = urls.first,
           let image = NSImage(contentsOf: firstUrl) {
            insertImageAttachment(image)
            return true
        }

        // Check for raw image data
        if let image = NSImage(pasteboard: pboard) {
            insertImageAttachment(image)
            return true
        }

        return super.performDragOperation(sender)
    }

    // MARK: - Paste Support for Images

    override func paste(_ sender: Any?) {
        let pboard = NSPasteboard.general
        if let image = NSImage(pasteboard: pboard) {
            insertImageAttachment(image)
            return
        }
        super.paste(sender)
    }

    private func insertImageAttachment(_ image: NSImage) {
        guard let textStorage = self.textStorage else { return }

        // Scale image if it exceeds current container width
        let maxDisplayWidth: CGFloat = max(160, (textContainer?.containerSize.width ?? 200) - 28)
        var displaySize = image.size
        if displaySize.width > maxDisplayWidth {
            let scale = maxDisplayWidth / displaySize.width
            displaySize = NSSize(width: maxDisplayWidth, height: displaySize.height * scale)
            image.size = displaySize
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = NSRect(origin: .zero, size: displaySize)

        let attrStringWithImage = NSAttributedString(attachment: attachment)

        // Insert at current selection or at end
        let selectedRange = self.selectedRange()
        let insertionLocation = selectedRange.location != NSNotFound ? selectedRange.location : textStorage.length

        textStorage.beginEditing()
        textStorage.insert(attrStringWithImage, at: insertionLocation)
        textStorage.endEditing()

        // Move insertion cursor right after the image
        self.setSelectedRange(NSRange(location: insertionLocation + 1, length: 0))
        self.didChangeText()
    }
}

/// AppKit NSViewRepresentable wrapper for the rich note text & image editor.
struct NoteTextEditorView: NSViewRepresentable {
    let plainContent: String
    let rtfdDataBase64: String?
    let onContextMenu: () -> NSMenu?
    let onContentChange: (String, String?) -> Void

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
        textView.isRichText = true
        textView.importsGraphics = true
        textView.allowsImageEditing = true
        textView.allowsUndo = true

        // Register for image drag & drop
        textView.registerForDraggedTypes([.fileURL, .png, .tiff])

        // Top margin for traffic lights and comfortable margins
        textView.textContainerInset = NSSize(width: 14, height: 12)
        scrollView.contentInsets = NSEdgeInsets(top: 26, left: 0, bottom: 8, right: 0)

        // Load initial content (RTFD with images or plain text)
        if let base64 = rtfdDataBase64, let data = Data(base64Encoded: base64),
           let attrStr = NSAttributedString(rtfd: data, documentAttributes: nil) {
            textView.textStorage?.setAttributedString(attrStr)
        } else if !plainContent.isEmpty {
            textView.string = plainContent
        }

        textView.onContextMenu = onContextMenu
        textView.onContentChange = onContentChange

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.textView?.onContextMenu = onContextMenu
        context.coordinator.textView?.onContentChange = onContentChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var textView: CustomNoteTextView?
    }
}
