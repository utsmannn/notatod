import Foundation
import Observation

@MainActor
@Observable
final class SyncState {
    enum Status: Equatable {
        case notConnected
        case synced(lastSyncedAt: Date?)
        case syncing
        case offline
        case error(message: String)

        var displayText: String {
            switch self {
            case .notConnected:
                return "Google Drive: Not connected"
            case .synced:
                return "Synced ✓"
            case .syncing:
                return "Syncing…"
            case .offline:
                return "Offline — changes saved locally"
            case .error(let message):
                return message.isEmpty ? "Sync error — tap to retry" : message
            }
        }
    }

    var status: Status = .notConnected
    var lastSyncedAt: Date?

    func markSyncing() {
        status = .syncing
    }

    func markSynced(at date: Date = .now) {
        lastSyncedAt = date
        status = .synced(lastSyncedAt: date)
    }

    func markOffline() {
        status = .offline
    }

    func markError(_ message: String = "Sync error — tap to retry") {
        status = .error(message: message)
    }

    func markNotConnected() {
        status = .notConnected
    }
}
