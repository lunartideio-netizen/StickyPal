import Foundation

struct StickyNote: Codable, Identifiable, Sendable {
    let id: UUID
    var content: String
    var rtfdDataBase64: String?
    var colorTag: String
    var themeMode: String
    var isCollapsed: Bool
    var opacity: Double
    var positionX: Double
    var positionY: Double
    var width: Double
    var height: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        content: String = "",
        rtfdDataBase64: String? = nil,
        colorTag: String = "gray",
        themeMode: String = "classic",
        isCollapsed: Bool = false,
        opacity: Double = 1.0,
        positionX: Double = 0,
        positionY: Double = 0,
        width: Double = 240,
        height: Double = 180
    ) {
        self.id = UUID()
        self.content = content
        self.rtfdDataBase64 = rtfdDataBase64
        self.colorTag = colorTag
        self.themeMode = themeMode
        self.isCollapsed = isCollapsed
        self.opacity = opacity
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, content, rtfdDataBase64, colorTag, themeMode, isCollapsed, opacity
        case positionX, positionY, width, height, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        self.rtfdDataBase64 = try container.decodeIfPresent(String.self, forKey: .rtfdDataBase64)
        self.colorTag = try container.decodeIfPresent(String.self, forKey: .colorTag) ?? "gray"
        self.themeMode = try container.decodeIfPresent(String.self, forKey: .themeMode) ?? "classic"
        self.isCollapsed = try container.decodeIfPresent(Bool.self, forKey: .isCollapsed) ?? false
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.positionX = try container.decode(Double.self, forKey: .positionX)
        self.positionY = try container.decode(Double.self, forKey: .positionY)
        self.width = try container.decode(Double.self, forKey: .width)
        self.height = try container.decode(Double.self, forKey: .height)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
