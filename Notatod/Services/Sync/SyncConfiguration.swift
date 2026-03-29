import Foundation

struct SyncConfiguration: Sendable {
    let googleClientID: String
    let googleClientSecret: String?
    let googleRedirectURI: String?

    var isConfigured: Bool {
        !googleClientID.isEmpty
    }
}

enum SyncConfigurationLoader {
    enum ConfigurationError: Error, LocalizedError {
        case missingFile
        case invalidFormat
        case missingRequiredKeys

        var errorDescription: String? {
            switch self {
            case .missingFile:
                return "SyncSecrets.plist not found"
            case .invalidFormat:
                return "SyncSecrets.plist format is invalid"
            case .missingRequiredKeys:
                return "SyncSecrets.plist is missing GOOGLE_CLIENT_ID"
            }
        }
    }

    static func load(bundle: Bundle = .main) throws -> SyncConfiguration {
        let url = bundle.url(forResource: "SyncSecrets", withExtension: "plist", subdirectory: "Config")
            ?? bundle.url(forResource: "SyncSecrets", withExtension: "plist")

        guard let url else {
            throw ConfigurationError.missingFile
        }

        let data = try Data(contentsOf: url)
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw ConfigurationError.invalidFormat
        }

        guard let clientID = plist["GOOGLE_CLIENT_ID"] as? String,
              !clientID.isEmpty else {
            throw ConfigurationError.missingRequiredKeys
        }

        let redirectURI = (plist["GOOGLE_REDIRECT_URI"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        return SyncConfiguration(
            googleClientID: clientID,
            googleClientSecret: plist["GOOGLE_CLIENT_SECRET"] as? String,
            googleRedirectURI: redirectURI?.isEmpty == true ? nil : redirectURI
        )
    }

    static func loadIfAvailable(bundle: Bundle = .main) -> SyncConfiguration? {
        try? load(bundle: bundle)
    }
}
