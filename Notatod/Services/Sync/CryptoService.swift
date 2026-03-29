import CommonCrypto
import CryptoKit
import Foundation

struct CryptoService {
    enum CryptoError: Error, LocalizedError {
        case invalidSaltLength
        case invalidCombinedData
        case keyDerivationFailed(CCCryptorStatus)
        case invalidPasswordEncoding

        var errorDescription: String? {
            switch self {
            case .invalidSaltLength:
                return "Salt must be 32 bytes"
            case .invalidCombinedData:
                return "Encrypted payload is malformed"
            case .keyDerivationFailed(let status):
                return "PBKDF2 failed with status \(status)"
            case .invalidPasswordEncoding:
                return "Password encoding failed"
            }
        }
    }

    struct EncryptedPayload: Codable {
        let nonce: Data
        let ciphertext: Data
        let tag: Data

        var combined: Data {
            nonce + ciphertext + tag
        }

        init(sealedBox: AES.GCM.SealedBox) {
            self.nonce = sealedBox.nonce.withUnsafeBytes { Data($0) }
            self.ciphertext = sealedBox.ciphertext
            self.tag = sealedBox.tag
        }

        init(combined: Data) throws {
            guard combined.count >= 12 + 16 else {
                throw CryptoError.invalidCombinedData
            }

            self.nonce = combined.prefix(12)
            self.tag = combined.suffix(16)
            self.ciphertext = combined.dropFirst(12).dropLast(16)
        }

        func sealedBox() throws -> AES.GCM.SealedBox {
            try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: nonce),
                ciphertext: ciphertext,
                tag: tag
            )
        }
    }

    let iterations: Int
    let keyLength: Int

    init(iterations: Int = 600_000, keyLength: Int = 32) {
        self.iterations = iterations
        self.keyLength = keyLength
    }

    func generateSalt(length: Int = 32) -> Data {
        Data((0..<length).map { _ in UInt8.random(in: .min ... .max) })
    }

    func deriveKey(password: String, salt: Data) throws -> SymmetricKey {
        guard salt.count == 32 else {
            throw CryptoError.invalidSaltLength
        }

        guard let passwordData = password.data(using: .utf8) else {
            throw CryptoError.invalidPasswordEncoding
        }

        var derived = Data(count: keyLength)
        let status = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw CryptoError.keyDerivationFailed(status)
        }

        return SymmetricKey(data: derived)
    }

    func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> EncryptedPayload {
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        return EncryptedPayload(sealedBox: sealedBox)
    }

    func decrypt(_ payload: EncryptedPayload, using key: SymmetricKey) throws -> Data {
        try AES.GCM.open(payload.sealedBox(), using: key)
    }

    func encryptString(_ plaintext: String, using key: SymmetricKey) throws -> EncryptedPayload {
        try encrypt(Data(plaintext.utf8), using: key)
    }

    func decryptString(_ payload: EncryptedPayload, using key: SymmetricKey) throws -> String {
        let data = try decrypt(payload, using: key)
        return String(decoding: data, as: UTF8.self)
    }
}
