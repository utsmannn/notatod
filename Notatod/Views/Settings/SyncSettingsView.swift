import SwiftUI

struct SyncSettingsView: View {
    @Environment(SyncService.self) private var syncService

    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath.icloud")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sync with Google Drive")
                            .font(.headline)

                        Text("Your notes are stored in a dedicated folder in your Google Drive. Sign in using the native Apple authentication sheet to start syncing this Mac’s notes.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Status") {
                LabeledContent("Sync") {
                    Text(syncService.statusText)
                        .foregroundStyle(statusColor)
                }

                if syncService.hasStoredTokens {
                    LabeledContent("Account") {
                        Text(syncService.connectedEmail ?? "Connected, but account email is not available yet")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                if syncService.hasStoredTokens {
                    Button("Disconnect Google Drive") {
                        syncService.signOut()
                    }
                } else {
                    Button("Sync with Google Drive") {
                        Task {
                            await syncService.signIn()
                        }
                    }
                    .disabled(!syncService.isConfigured)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How it works")
                        .font(.subheadline.weight(.semibold))
                    Text("1. Click Sync with Google Drive")
                    Text("2. Choose the Google account you want to use")
                    Text("3. Allow access to save and sync your notes")
                    Text("Once connected, local note changes are pushed to your Google Drive automatically.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var statusColor: Color {
        switch syncService.syncState.status {
        case .notConnected:
            return .secondary
        case .synced:
            return .green
        case .syncing:
            return .blue
        case .offline:
            return .orange
        case .error:
            return .red
        }
    }
}
