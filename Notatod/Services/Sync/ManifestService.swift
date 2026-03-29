import Foundation

struct SyncManifest: Codable, Sendable {
    struct Entry: Codable, Sendable {
        let modifiedAt: Date
        let driveFileID: String
    }

    let version: Int
    let notes: [UUID: Entry]

    init(version: Int = 1, notes: [UUID: Entry] = [:]) {
        self.version = version
        self.notes = notes
    }
}

struct ManifestService {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func encode(_ manifest: SyncManifest) throws -> Data {
        try encoder.encode(manifest)
    }

    func decode(_ data: Data) throws -> SyncManifest {
        try decoder.decode(SyncManifest.self, from: data)
    }

    func updating(_ manifest: SyncManifest, noteID: UUID, modifiedAt: Date, driveFileID: String) -> SyncManifest {
        var notes = manifest.notes
        notes[noteID] = .init(modifiedAt: modifiedAt, driveFileID: driveFileID)
        return SyncManifest(version: manifest.version, notes: notes)
    }

    func removing(_ manifest: SyncManifest, noteID: UUID) -> SyncManifest {
        var notes = manifest.notes
        notes.removeValue(forKey: noteID)
        return SyncManifest(version: manifest.version, notes: notes)
    }
}
