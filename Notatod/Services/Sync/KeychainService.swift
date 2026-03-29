import Foundation
import Security

struct KeychainService {
    enum InteractionPolicy {
        case allow
        case failSilently
    }

    enum KeychainError: Error, LocalizedError {
        case unexpectedStatus(OSStatus)
        case invalidData

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status):
                if let message = SecCopyErrorMessageString(status, nil) as String? {
                    return message
                }
                return "Keychain error: \(status)"
            case .invalidData:
                return "Invalid keychain data"
            }
        }
    }

    private let service: String

    init(service: String = "com.notatod.app.sync") {
        self.service = service
    }

    func save(_ data: Data, account: String) throws {
        let query = baseQuery(account: account)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var createQuery = query
            createQuery[kSecValueData as String] = data
            let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
            guard createStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(createStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func load(account: String, interactionPolicy: InteractionPolicy = .allow) throws -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        if interactionPolicy == .failSilently {
            query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            return data
        case errSecItemNotFound, errSecInteractionNotAllowed, errSecUserCanceled, errSecAuthFailed:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func saveString(_ value: String, account: String) throws {
        try save(Data(value.utf8), account: account)
    }

    func loadString(account: String) throws -> String? {
        guard let data = try load(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
    }
}
