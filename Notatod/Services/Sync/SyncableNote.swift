import Foundation

struct SyncableNote: Codable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let isPinned: Bool
    let createdAt: Date
    let modifiedAt: Date

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func toJSON() throws -> Data {
        try Self.encoder.encode(self)
    }

    static func fromJSON(_ data: Data) throws -> SyncableNote {
        try Self.decoder.decode(SyncableNote.self, from: data)
    }
}
