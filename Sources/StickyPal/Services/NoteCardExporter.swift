import AppKit

@MainActor
enum NoteCardExporter {

    static func renderCard(panel: NotePanel?, note: StickyNote, attrString: NSAttributedString?) -> NSImage? {
        let cardWidth: CGFloat = max(240, CGFloat(note.width))
        let cardHeight: CGFloat = max(180, CGFloat(note.height))
        let padding: CGFloat = 20.0
        let shadowBlur: CGFloat = 16.0

        let totalWidth = cardWidth + padding * 2
        let totalHeight = cardHeight + padding * 2
        let scale: CGFloat = 2.0

        let pixelWidth = Int(totalWidth * scale)
        let pixelHeight = Int(totalHeight * scale)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: pixelWidth * 4,
            bitsPerPixel: 32
        ) else { return nil }

        rep.size = NSSize(width: totalWidth, height: totalHeight)

        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context
        let cg = context.cgContext

        // 1. Clear canvas to 100% transparent alpha
        let fullBounds = CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
        cg.clear(fullBounds)

        let cardRect = CGRect(x: padding, y: padding, width: cardWidth, height: cardHeight)
        let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 14, cornerHeight: 14, transform: nil)

        // 2. Draw soft macOS window drop shadow (prevents WeChat white corner artifacts)
        cg.saveGState()
        let shadowColor = NSColor.black.withAlphaComponent(0.28).cgColor
        cg.setShadow(offset: CGSize(width: 0, height: -6), blur: shadowBlur, color: shadowColor)
        cg.addPath(cardPath)
        cg.setFillColor(NSColor.black.cgColor)
        cg.fillPath()
        cg.restoreGState()

        // 3. Clip inside card
        cg.saveGState()
        cg.addPath(cardPath)
        cg.clip()

        // 4. Draw Background: capture live Metal shader frame or frosted glass
        if note.themeMode != "classic", let liveCG = panel?.captureLiveFrame(size: cardRect.size) {
            cg.draw(liveCG, in: cardRect)
        } else {
            drawBackground(theme: note.themeMode, colorTag: note.colorTag, bounds: cardRect, in: cg)
        }

        // 5. Draw Traffic Light Buttons
        let redColor = NSColor(srgbRed: 1.0, green: 0.37, blue: 0.34, alpha: 1.0).cgColor
        let yellowColor = NSColor(srgbRed: 1.0, green: 0.74, blue: 0.18, alpha: 1.0).cgColor
        let greenColor = NSColor(srgbRed: 0.15, green: 0.79, blue: 0.25, alpha: 1.0).cgColor

        let topY = padding + cardHeight - 20
        let circleSize: CGFloat = 11

        cg.setFillColor(redColor)
        cg.fillEllipse(in: CGRect(x: padding + 14, y: topY, width: circleSize, height: circleSize))

        cg.setFillColor(yellowColor)
        cg.fillEllipse(in: CGRect(x: padding + 14 + 18, y: topY, width: circleSize, height: circleSize))

        cg.setFillColor(greenColor)
        cg.fillEllipse(in: CGRect(x: padding + 14 + 36, y: topY, width: circleSize, height: circleSize))

        // 6. Draw Content (Text and attachments)
        let textRect = CGRect(x: padding + 14, y: padding + 12, width: cardWidth - 28, height: cardHeight - 42)

        if let attr = attrString, attr.length > 0 {
            attr.draw(in: textRect)
        } else if !note.content.isEmpty {
            let defaultAttr: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13.5, weight: .regular),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: note.content, attributes: defaultAttr)
            str.draw(in: textRect)
        }

        cg.restoreGState()
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight))
        image.addRepresentation(rep)
        return image
    }

    private static func drawBackground(theme: String, colorTag: String, bounds: CGRect, in cg: CGContext) {
        let space = CGColorSpaceCreateDeviceRGB()

        switch theme {
        case "fluid":
            let colors = [
                NSColor(srgbRed: 0.18, green: 0.10, blue: 0.48, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.95, green: 0.38, blue: 0.52, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.98, green: 0.68, blue: 0.28, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.18, green: 0.58, blue: 0.95, alpha: 1.0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 0.35, 0.7, 1.0]) {
                cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: bounds.height), options: [])
            }

        case "aurora":
            let colors = [
                NSColor(srgbRed: 0.02, green: 0.05, blue: 0.14, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.05, green: 0.45, blue: 0.68, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.10, green: 0.92, blue: 0.62, alpha: 1.0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 0.5, 1.0]) {
                cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: bounds.height), end: CGPoint(x: bounds.width, y: 0), options: [])
            }

        case "chrome":
            let colors = [
                NSColor(srgbRed: 0.18, green: 0.20, blue: 0.24, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.55, green: 0.58, blue: 0.65, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.92, green: 0.95, blue: 0.98, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.35, green: 0.38, blue: 0.45, alpha: 1.0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 0.4, 0.7, 1.0]) {
                cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: bounds.height), options: [])
            }

        case "neon":
            let colors = [
                NSColor(srgbRed: 0.06, green: 0.03, blue: 0.12, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.48, green: 0.12, blue: 0.85, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.95, green: 0.10, blue: 0.58, alpha: 1.0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 0.5, 1.0]) {
                cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: bounds.height), options: [])
            }

        case "klein":
            let colors = [
                NSColor(srgbRed: 0.01, green: 0.06, blue: 0.24, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.0, green: 0.18, blue: 0.72, alpha: 1.0).cgColor,
                NSColor(srgbRed: 0.08, green: 0.35, blue: 0.98, alpha: 1.0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 0.5, 1.0]) {
                cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: bounds.height), options: [])
            }

        default: // classic
            cg.setFillColor(NSColor(calibratedWhite: 0.18, alpha: 0.96).cgColor)
            cg.fill(bounds)
            let tagColor = NoteColors.color(for: colorTag)
            cg.setFillColor(tagColor.cgColor)
            cg.fill(bounds)
        }
    }

    static func copyCardToClipboard(panel: NotePanel?, note: StickyNote, attrString: NSAttributedString?) -> Bool {
        guard let image = renderCard(panel: panel, note: note, attrString: attrString) else { return false }
        guard let pngData = image.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }) else { return false }

        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.setData(pngData, forType: .png)
        return true
    }

    static func saveCardToDesktop(panel: NotePanel?, note: StickyNote, attrString: NSAttributedString?) -> String? {
        guard let image = renderCard(panel: panel, note: note, attrString: attrString) else { return nil }
        guard let pngData = image.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }) else { return nil }

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let fileName = "StickyPal-\(formatter.string(from: Date())).png"
        let fileURL = desktopURL.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("[StickyPal Export Error]:", error)
            return nil
        }
    }
}
