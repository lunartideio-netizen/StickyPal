import Foundation

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [StickyNote] = []

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("StickyPal", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: appSupport, withIntermediateDirectories: true
        )

        self.fileURL = appSupport.appendingPathComponent("notes.json")
        load()
    }

    // MARK: - CRUD

    func add(_ note: StickyNote) {
        notes.append(note)
        scheduleSave()
    }

    func delete(id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func update(id: UUID, _ transform: (inout StickyNote) -> Void) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        transform(&notes[index])
        notes[index].updatedAt = Date()
        scheduleSave()
    }

    func note(for id: UUID) -> StickyNote? {
        notes.first { $0.id == id }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            notes = try decoder.decode([StickyNote].self, from: data)
        } catch {
            print("NoteStore: failed to load notes: (error)")
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self.persist()
        }
    }

    func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("NoteStore: failed to save notes: (error)")
        }
    }
}
