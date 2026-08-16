import AppKit

enum NoteColors {
    static func color(for tag: String) -> NSColor {
        switch tag {
        case "yellow":
            return NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? NSColor(srgbRed: 0.95, green: 0.82, blue: 0.32, alpha: 0.22)
                    : NSColor(srgbRed: 0.99, green: 0.88, blue: 0.42, alpha: 0.18)
            }
        case "blue":
            return NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? NSColor(srgbRed: 0.30, green: 0.65, blue: 0.98, alpha: 0.22)
                    : NSColor(srgbRed: 0.38, green: 0.70, blue: 0.99, alpha: 0.18)
            }
        case "green":
            return NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? NSColor(srgbRed: 0.35, green: 0.82, blue: 0.48, alpha: 0.22)
                    : NSColor(srgbRed: 0.42, green: 0.86, blue: 0.54, alpha: 0.18)
            }
        case "pink":
            return NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? NSColor(srgbRed: 0.95, green: 0.48, blue: 0.65, alpha: 0.22)
                    : NSColor(srgbRed: 0.98, green: 0.54, blue: 0.70, alpha: 0.18)
            }
        case "purple":
            return NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? NSColor(srgbRed: 0.72, green: 0.48, blue: 0.98, alpha: 0.22)
                    : NSColor(srgbRed: 0.76, green: 0.54, blue: 0.98, alpha: 0.18)
            }
        default: // gray or none
            return .clear
        }
    }

    static func makeDotImage(for tag: String, size: CGFloat = 12) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let dotColor: NSColor
        switch tag {
        case "yellow":
            dotColor = NSColor.systemYellow
        case "blue":
            dotColor = NSColor.systemBlue
        case "green":
            dotColor = NSColor.systemGreen
        case "pink":
            dotColor = NSColor.systemPink
        case "purple":
            dotColor = NSColor.systemPurple
        default:
            dotColor = NSColor.systemGray
        }
        let path = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size - 2, height: size - 2))
        dotColor.setFill()
        path.fill()
        image.unlockFocus()
        return image
    }
}
