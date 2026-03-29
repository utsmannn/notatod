import Foundation

@MainActor
final class SyncEngine {
    private let syncState: SyncState
    private let networkMonitor: NetworkMonitor
    private let debounceInterval: TimeInterval
    private var pendingTask: Task<Void, Never>?
    private var dirtyNoteIDs = Set<UUID>()
    private var hasStarted = false

    var onFlush: (@MainActor (Set<UUID>) async throws -> Void)?

    init(
        syncState: SyncState,
        networkMonitor: NetworkMonitor = NetworkMonitor(),
        debounceInterval: TimeInterval = 2.0
    ) {
        self.syncState = syncState
        self.networkMonitor = networkMonitor
        self.debounceInterval = debounceInterval

        self.networkMonitor.onStatusChange = { [weak self] isOnline in
            Task { @MainActor in
                guard let self else { return }
                if isOnline {
                    if self.dirtyNoteIDs.isEmpty {
                        self.syncState.markSynced(at: self.syncState.lastSyncedAt ?? .now)
                    } else {
                        await self.scheduleFlush()
                    }
                } else {
                    self.syncState.markOffline()
                }
            }
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        networkMonitor.start()
    }

    func stop() {
        pendingTask?.cancel()
        pendingTask = nil
        dirtyNoteIDs.removeAll()
        guard hasStarted else { return }
        hasStarted = false
        networkMonitor.stop()
    }

    func enqueue(noteID: UUID) {
        dirtyNoteIDs.insert(noteID)
        SyncDebugLogger.log("[SyncEngine.enqueue] note=\(noteID) dirtyCount=\(dirtyNoteIDs.count)")
        pendingTask?.cancel()
        pendingTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(debounceInterval))
            await self.flush()
        }
    }

    func flush() async {
        SyncDebugLogger.log("[SyncEngine.flush] online=\(networkMonitor.isOnline) pending=\(dirtyNoteIDs.count)")
        guard networkMonitor.isOnline else {
            syncState.markOffline()
            return
        }

        let batch = dirtyNoteIDs
        guard !batch.isEmpty else { return }

        dirtyNoteIDs.removeAll()
        syncState.markSyncing()

        do {
            try await onFlush?(batch)
            SyncDebugLogger.log("[SyncEngine.flush] success batch=\(batch)")
            syncState.markSynced()
        } catch {
            SyncDebugLogger.log("[SyncEngine.flush] error=\(error.localizedDescription)")
            dirtyNoteIDs.formUnion(batch)
            if let urlError = extractURLError(from: error), [.notConnectedToInternet, .networkConnectionLost].contains(urlError.code) {
                syncState.markOffline()
            } else {
                syncState.markError(error.localizedDescription)
            }
        }
    }

    private func scheduleFlush() async {
        pendingTask?.cancel()
        pendingTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(debounceInterval))
            await self.flush()
        }
    }

    private func extractURLError(from error: Error) -> URLError? {
        if let urlError = error as? URLError {
            return urlError
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return URLError(.init(rawValue: nsError.code), userInfo: nsError.userInfo)
        }

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return extractURLError(from: underlyingError)
        }

        return nil
    }
}
