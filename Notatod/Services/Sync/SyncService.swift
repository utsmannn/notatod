import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SyncService {
    enum Availability {
        case configured(SyncConfiguration)
        case missingConfiguration
        case invalidConfiguration(String)
    }

    private enum Constants {
        static let folderName = ".notatod"
        static let manifestFileName = "manifest.json"
        static let noteMimeType = "application/json"
    }

    private(set) var availability: Availability = .missingConfiguration
    private(set) var connectedEmail: String?
    private(set) var hasStoredTokens = false

    let syncState: SyncState
    private(set) var authService: GoogleAuthService?

    private let manifestService: ManifestService
    private let syncEngine: SyncEngine

    private var driveService: GoogleDriveService?
    private var modelContext: ModelContext?
    private var manifest = SyncManifest()
    private var folderID: String?
    private var manifestFileID: String?
    private var isBootstrapping = false

    init(syncState: SyncState? = nil, manifestService: ManifestService = ManifestService()) {
        self.syncState = syncState ?? SyncState()
        self.manifestService = manifestService
        self.syncEngine = SyncEngine(syncState: self.syncState)
        self.syncEngine.onFlush = { [weak self] noteIDs in
            guard let self else { return }
            try await self.uploadNotes(withIDs: noteIDs)
        }
        reloadConfiguration()
        refreshStoredSessionState()
    }

    var statusText: String {
        syncState.status.displayText
    }

    var isConfigured: Bool {
        if case .configured = availability { return true }
        return false
    }

    var configurationMessage: String {
        switch availability {
        case .configured:
            return "Google OAuth configuration detected"
        case .missingConfiguration:
            return "SyncSecrets.plist is not available"
        case .invalidConfiguration(let message):
            return message
        }
    }

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        if hasStoredTokens {
            syncEngine.start()
            Task { [weak self] in
                await self?.restoreRemoteSessionIfNeeded()
            }
        }
    }

    func reloadConfiguration() {
        do {
            let configuration = try SyncConfigurationLoader.load()
            availability = .configured(configuration)
            authService = GoogleAuthService(configuration: GoogleOAuthConfiguration(
                clientID: configuration.googleClientID,
                clientSecret: configuration.googleClientSecret,
                redirectURI: configuration.googleRedirectURI
            ))
            driveService = nil
            if hasStoredTokens {
                syncState.markSynced(at: syncState.lastSyncedAt ?? .now)
            } else {
                syncState.markNotConnected()
            }
        } catch let error as SyncConfigurationLoader.ConfigurationError {
            availability = .invalidConfiguration(error.localizedDescription)
            authService = nil
            driveService = nil
            syncState.markNotConnected()
        } catch {
            availability = .invalidConfiguration(error.localizedDescription)
            authService = nil
            driveService = nil
            syncState.markError(error.localizedDescription)
        }
    }

    func refreshStoredSessionState() {
        guard let authService else {
            hasStoredTokens = false
            connectedEmail = nil
            return
        }

        do {
            let tokens = try authService.currentTokens(interactionPolicy: KeychainService.InteractionPolicy.failSilently)
            hasStoredTokens = tokens != nil
            connectedEmail = tokens?.email
            if hasStoredTokens {
                syncState.markSynced(at: syncState.lastSyncedAt ?? .now)
                syncEngine.start()
                if connectedEmail == nil {
                    Task { [weak self] in
                        await self?.refreshConnectedEmail()
                    }
                }
                Task { [weak self] in
                    await self?.restoreRemoteSessionIfNeeded()
                }
            } else {
                syncEngine.stop()
                syncState.markNotConnected()
            }
        } catch {
            hasStoredTokens = false
            connectedEmail = nil
            syncEngine.stop()
            syncState.markNotConnected()
        }
    }

    func signIn() async {
        guard let authService else {
            syncState.markError("Sync configuration is not available")
            return
        }

        syncState.markSyncing()
        do {
            let tokens = try await authService.signIn()
            hasStoredTokens = true
            connectedEmail = tokens.email
            syncEngine.start()
            try await bootstrapRemoteState()
        } catch {
            syncState.markError(error.localizedDescription)
        }
    }

    func signOut() {
        guard let authService else { return }
        do {
            try authService.signOut()
            hasStoredTokens = false
            connectedEmail = nil
            driveService = nil
            folderID = nil
            manifestFileID = nil
            manifest = SyncManifest()
            syncEngine.stop()
            syncState.markNotConnected()
        } catch {
            syncState.markError(error.localizedDescription)
        }
    }

    func noteDidChange(_ note: Note) {
        SyncDebugLogger.log("[SyncService.noteDidChange] note=\(note.id) hasStoredTokens=\(hasStoredTokens)")
        guard hasStoredTokens else { return }
        syncEngine.start()
        syncEngine.enqueue(noteID: note.id)
    }

    func noteDidDelete(id noteID: UUID) async throws {
        guard hasStoredTokens else { return }
        try await configureDriveSessionIfNeeded()
        guard let driveService else {
            throw SyncError.notReady("Sync session is not ready yet")
        }

        syncState.markSyncing()

        if let entry = manifest.notes[noteID] {
            try await driveService.deleteFile(fileID: entry.driveFileID)
        }

        manifest = manifestService.removing(manifest, noteID: noteID)
        try await persistManifest(using: driveService)
        syncState.markSynced()
    }

    private func refreshConnectedEmail() async {
        guard let authService else { return }

        do {
            connectedEmail = try await authService.resolveAccountEmail()
        } catch {
            connectedEmail = nil
        }
    }

    private func restoreRemoteSessionIfNeeded() async {
        guard hasStoredTokens, modelContext != nil, !isBootstrapping else { return }

        do {
            try await configureDriveSessionIfNeeded()
            syncState.markSynced(at: syncState.lastSyncedAt ?? .now)
        } catch {
            syncState.markError(error.localizedDescription)
        }
    }

    private func bootstrapRemoteState() async throws {
        guard modelContext != nil else {
            throw SyncError.notReady("Sync storage is not attached yet")
        }

        isBootstrapping = true
        defer { isBootstrapping = false }

        syncState.markSyncing()
        try await configureDriveSessionIfNeeded(forceReload: true)

        let notes = try fetchAllNotes()
        var updatedManifest = manifest

        for note in notes {
            if let entry = manifest.notes[note.id], entry.modifiedAt >= note.modifiedAt {
                continue
            }

            let driveFileID = try await upload(note: note, existingFileID: manifest.notes[note.id]?.driveFileID)
            updatedManifest = manifestService.updating(
                updatedManifest,
                noteID: note.id,
                modifiedAt: note.modifiedAt,
                driveFileID: driveFileID
            )
        }

        manifest = updatedManifest
        guard let driveService else {
            throw SyncError.notReady("Sync session is not ready yet")
        }
        try await persistManifest(using: driveService)
        syncState.markSynced()
    }

    private func configureDriveSessionIfNeeded(forceReload: Bool = false) async throws {
        guard let authService else {
            throw SyncError.notReady("Google authentication is not configured")
        }

        if driveService == nil || forceReload {
            driveService = GoogleDriveService { [weak authService] in
                try await authService?.validAccessToken()
            }
        }

        guard let driveService else {
            throw SyncError.notReady("Google Drive service is unavailable")
        }

        if folderID == nil || forceReload {
            let folder = try await ensureSyncFolder(using: driveService)
            folderID = folder.id
        }

        let manifestFile = try await fetchManifestFile(using: driveService, forceReload: forceReload)
        manifestFileID = manifestFile?.id
        manifest = try await loadManifest(using: driveService, manifestFile: manifestFile)
    }

    private func ensureSyncFolder(using driveService: GoogleDriveService) async throws -> GoogleDriveFile {
        let query = [
            "name = '\(escapedQueryValue(Constants.folderName))'",
            "trashed = false",
            "mimeType = 'application/vnd.google-apps.folder'"
        ].joined(separator: " and ")

        if let existing = try await driveService.listFiles(query: query, pageSize: 1).first {
            return existing
        }

        let created = try await driveService.createFolder(named: Constants.folderName)
        return GoogleDriveFile(id: created.id, name: created.name ?? Constants.folderName, mimeType: "application/vnd.google-apps.folder", modifiedTime: nil)
    }

    private func fetchManifestFile(using driveService: GoogleDriveService, forceReload: Bool) async throws -> GoogleDriveFile? {
        guard let folderID else {
            throw SyncError.notReady("Sync folder is unavailable")
        }

        let query = [
            "'\(folderID)' in parents",
            "name = '\(escapedQueryValue(Constants.manifestFileName))'",
            "trashed = false"
        ].joined(separator: " and ")
        return try await driveService.listFiles(query: query, pageSize: 1).first
    }

    private func loadManifest(using driveService: GoogleDriveService, manifestFile: GoogleDriveFile?) async throws -> SyncManifest {
        guard let manifestFile else {
            return SyncManifest()
        }

        let data = try await driveService.downloadFile(fileID: manifestFile.id)
        return try manifestService.decode(data)
    }

    private func uploadNotes(withIDs noteIDs: Set<UUID>) async throws {
        guard !noteIDs.isEmpty else { return }
        try await configureDriveSessionIfNeeded()

        let notes = try fetchNotes(withIDs: noteIDs)
        guard let driveService else {
            throw SyncError.notReady("Sync session is not ready yet")
        }

        var updatedManifest = manifest
        for note in notes {
            let driveFileID = try await upload(note: note, existingFileID: manifest.notes[note.id]?.driveFileID)
            updatedManifest = manifestService.updating(
                updatedManifest,
                noteID: note.id,
                modifiedAt: note.modifiedAt,
                driveFileID: driveFileID
            )
        }

        manifest = updatedManifest
        try await persistManifest(using: driveService)
    }

    private func upload(note: Note, existingFileID: String?) async throws -> String {
        guard let driveService else {
            throw SyncError.notReady("Sync session is not ready yet")
        }
        guard let folderID else {
            throw SyncError.notReady("Sync folder is unavailable")
        }

        let payload = SyncableNote(
            id: note.id,
            title: note.title,
            content: note.content,
            isPinned: note.isPinned,
            createdAt: note.createdAt,
            modifiedAt: note.modifiedAt
        )

        let response = try await driveService.uploadFile(
            named: noteFileName(for: note.id),
            data: try payload.toJSON(),
            mimeType: Constants.noteMimeType,
            parentID: folderID,
            existingFileID: existingFileID
        )
        return response.id
    }

    private func persistManifest(using driveService: GoogleDriveService) async throws {
        guard let folderID else {
            throw SyncError.notReady("Sync folder is unavailable")
        }

        let response = try await driveService.uploadFile(
            named: Constants.manifestFileName,
            data: try manifestService.encode(manifest),
            mimeType: Constants.noteMimeType,
            parentID: folderID,
            existingFileID: manifestFileID
        )
        manifestFileID = response.id
    }

    private func fetchAllNotes() throws -> [Note] {
        guard let modelContext else {
            throw SyncError.notReady("Sync storage is not attached yet")
        }
        return try modelContext.fetch(FetchDescriptor<Note>())
    }

    private func fetchNotes(withIDs noteIDs: Set<UUID>) throws -> [Note] {
        try fetchAllNotes().filter { noteIDs.contains($0.id) }
    }

    private func noteFileName(for noteID: UUID) -> String {
        "\(noteID.uuidString.lowercased()).json"
    }

    private func escapedQueryValue(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "\\'")
    }
}

extension SyncService {
    enum SyncError: LocalizedError {
        case notReady(String)

        var errorDescription: String? {
            switch self {
            case .notReady(let message):
                return message
            }
        }
    }
}
