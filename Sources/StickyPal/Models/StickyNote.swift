import Foundation

struct StickyNote: Codable, Identifiable, Sendable {
    let id: UUID
    var content: String
    var rtfdDataBase64: String?
    var colorTag: String
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
        positionX: Double = 0,
        positionY: Double = 0,
        width: Double = 240,
        height: Double = 180
    ) {
        self.id = UUID()
        self.content = content
        self.rtfdDataBase64 = rtfdDataBase64
        self.colorTag = colorTag
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
