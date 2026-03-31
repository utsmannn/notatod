import AppKit
import AuthenticationServices
import CryptoKit
import Foundation
import Security

struct GoogleOAuthConfiguration {
    let clientID: String
    let clientSecret: String?
    let redirectURI: String?
    let scopes: [String]

    init(
        clientID: String,
        clientSecret: String? = nil,
        redirectURI: String? = nil,
        scopes: [String] = [
            "openid",
            "email",
            "profile",
            "https://www.googleapis.com/auth/drive.file"
        ]
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
}

struct GoogleTokenResponse: Codable, Sendable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?
    let tokenType: String
    let idToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
        case idToken = "id_token"
    }
}

struct GoogleStoredTokens: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiryDate: Date
    let idToken: String?
    let accountEmail: String?

    var isExpired: Bool {
        Date().addingTimeInterval(30) >= expiryDate
    }

    var email: String? {
        accountEmail ?? idToken.flatMap { GoogleIDTokenPayload.decode(from: $0)?.email }
    }
}

private struct GoogleIDTokenPayload: Decodable {
    let email: String?

    static func decode(from token: String) -> GoogleIDTokenPayload? {
        let segments = token.split(separator: ".")
        guard segments.count > 1 else { return nil }

        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = payload.count % 4
        if remainder != 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: payload) else { return nil }
        return try? JSONDecoder().decode(GoogleIDTokenPayload.self, from: data)
    }
}

private struct GoogleErrorResponse: Decodable {
    let error: GoogleErrorValue?
    let errorDescription: String?
    let errorSubtype: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case errorSubtype = "error_subtype"
        case message
    }

    var summary: String? {
        let parts = [
            error?.description,
            errorDescription,
            errorSubtype,
            message
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " — ")
    }
}

private enum GoogleErrorValue: Decodable {
    case string(String)
    case object(GoogleNestedError)

    var description: String? {
        switch self {
        case .string(let value):
            return value
        case .object(let value):
            return value.summary
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }

        self = .object(try container.decode(GoogleNestedError.self))
    }
}

private struct GoogleNestedError: Decodable {
    let message: String?
    let status: String?

    var summary: String? {
        [status, message]
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed?.isEmpty == false ? trimmed : nil
            }
            .joined(separator: " — ")
    }
}

@MainActor
final class GoogleAuthService: NSObject {
    enum AuthError: Error, LocalizedError {
        case invalidAuthorizationURL
        case missingAuthorizationCode
        case missingRefreshToken
        case invalidCallback
        case invalidResponse
        case oauthCancelled
        case invalidRedirectURI(String)
        case callbackSchemeNotRegistered(String)
        case callbackRejected(String)
        case cannotResolveGoogleHost
        case networkUnavailable
        case networkConnectionLost
        case authSessionFailed(String)
        case googleAPIError(context: String, message: String)
        case googleHTTPError(context: String, statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidAuthorizationURL:
                return "Failed to build Google authorization URL"
            case .missingAuthorizationCode:
                return "Google did not return an authorization code"
            case .missingRefreshToken:
                return "Google sign-in succeeded, but no refresh token was returned"
            case .invalidCallback:
                return "Google sign-in callback is invalid"
            case .invalidResponse:
                return "Google OAuth response is invalid"
            case .oauthCancelled:
                return "Google sign-in was cancelled"
            case .invalidRedirectURI(let message):
                return message
            case .callbackSchemeNotRegistered(let scheme):
                return "The app callback scheme \(scheme) is not registered in Info.plist"
            case .callbackRejected(let message):
                return message
            case .cannotResolveGoogleHost:
                return "Cannot resolve Google servers. Check DNS, VPN, proxy, or firewall settings"
            case .networkUnavailable:
                return "No network connection is available for Google sign-in"
            case .networkConnectionLost:
                return "The network connection was interrupted during Google sign-in"
            case .authSessionFailed(let message):
                return message
            case .googleAPIError(let context, let message):
                return "Google \(context) failed: \(message)"
            case .googleHTTPError(let context, let statusCode):
                return "Google \(context) failed with HTTP \(statusCode)"
            }
        }
    }

    private enum Constants {
        static let tokenAccount = "google.oauth.tokens"
        static let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        static let authBaseURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        static let userInfoURL = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
        static let redirectPath = "/oauth2redirect/google"
        static let schemePrefix = "com.googleusercontent.apps."
    }

    private struct GoogleUserInfoResponse: Decodable {
        let email: String?
    }

    private struct PKCEChallenge {
        let verifier: String
        let challenge: String
    }

    private let configuration: GoogleOAuthConfiguration
    private let keychain: KeychainService
    private let session: URLSession
    private var authSession: ASWebAuthenticationSession?

    init(
        configuration: GoogleOAuthConfiguration,
        keychain: KeychainService = KeychainService(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.keychain = keychain
        self.session = session
        super.init()
    }

    func signIn() async throws -> GoogleStoredTokens {
        let redirectURI = try resolvedRedirectURI()
        let redirectScheme = try resolvedRedirectScheme(from: redirectURI)
        try validateCallbackSchemeRegistration(redirectScheme)

        let pkce = makePKCEChallenge()
        let state = UUID().uuidString
        let authURL = try makeAuthorizationURL(state: state, redirectURI: redirectURI, pkce: pkce)

        let callbackURL = try await authenticate(using: authURL, callbackScheme: redirectScheme)
        let code = try extractAuthorizationCode(from: callbackURL, expectedState: state)
        let response = try await exchangeCodeForTokens(code, verifier: pkce.verifier, redirectURI: redirectURI)
        let stored = try store(response: response)
        return try await hydrateAccountEmail(for: stored)
    }

    func currentTokens(interactionPolicy: KeychainService.InteractionPolicy = .allow) throws -> GoogleStoredTokens? {
        guard let data = try keychain.load(account: Constants.tokenAccount, interactionPolicy: interactionPolicy) else { return nil }
        return try JSONDecoder().decode(GoogleStoredTokens.self, from: data)
    }

    func validAccessToken() async throws -> String? {
        guard let tokens = try currentTokens() else { return nil }
        if !tokens.isExpired {
            return tokens.accessToken
        }

        let refreshed = try await refreshAccessToken(using: tokens.refreshToken)
        return refreshed.accessToken
    }

    func resolveAccountEmail() async throws -> String? {
        guard let tokens = try currentTokens() else { return nil }
        let hydrated = try await hydrateAccountEmail(for: tokens)
        return hydrated.email
    }

    func signOut() throws {
        authSession?.cancel()
        authSession = nil
        try keychain.delete(account: Constants.tokenAccount)
    }

    private func authenticate(using authURL: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.authSession = nil
                    if let error {
                        continuation.resume(throwing: self?.mapAuthenticationError(error) ?? error)
                        return
                    }

                    guard let callbackURL else {
                        continuation.resume(throwing: AuthError.invalidCallback)
                        return
                    }

                    continuation.resume(returning: callbackURL)
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session

            if !session.start() {
                self.authSession = nil
                continuation.resume(throwing: AuthError.authSessionFailed("Google sign-in could not start the authentication session"))
            }
        }
    }

    private func resolvedRedirectURI() throws -> String {
        let redirectURI: String
        if let configuredRedirectURI = configuration.redirectURI?.trimmingCharacters(in: .whitespacesAndNewlines), !configuredRedirectURI.isEmpty {
            redirectURI = configuredRedirectURI
        } else {
            let trimmedClientID = configuration.clientID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedClientID.isEmpty else {
                throw AuthError.invalidRedirectURI("GOOGLE_CLIENT_ID is empty, so the Google redirect URI cannot be resolved")
            }

            redirectURI = "\(Constants.schemePrefix)\(trimmedClientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")):\(Constants.redirectPath)"
        }

        _ = try validatedRedirectComponents(for: redirectURI)
        return redirectURI
    }

    private func resolvedRedirectScheme(from redirectURI: String) throws -> String {
        let components = try validatedRedirectComponents(for: redirectURI)
        guard let scheme = components.scheme else {
            throw AuthError.invalidRedirectURI("Google redirect URI is missing a callback scheme")
        }
        return scheme
    }

    private func validatedRedirectComponents(for redirectURI: String) throws -> URLComponents {
        guard let components = URLComponents(string: redirectURI),
              let scheme = components.scheme,
              !scheme.isEmpty else {
            throw AuthError.invalidRedirectURI("Google redirect URI is malformed")
        }

        let expectedScheme = try expectedRedirectScheme()
        guard scheme == expectedScheme else {
            throw AuthError.invalidRedirectURI("Google redirect URI scheme \(scheme) does not match GOOGLE_CLIENT_ID")
        }

        guard scheme.hasPrefix(Constants.schemePrefix) else {
            throw AuthError.invalidRedirectURI("Google redirect URI must use the Google desktop callback scheme")
        }

        guard components.path == Constants.redirectPath else {
            throw AuthError.invalidRedirectURI("Google redirect URI path must be \(Constants.redirectPath)")
        }

        if let host = components.host, !host.isEmpty {
            throw AuthError.invalidRedirectURI("Google redirect URI must not include a host component")
        }

        return components
    }

    private func validateCallbackSchemeRegistration(_ scheme: String) throws {
        let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
        let registeredSchemes = urlTypes?
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 } ?? []

        guard registeredSchemes.contains(scheme) else {
            throw AuthError.callbackSchemeNotRegistered(scheme)
        }
    }

    private func expectedRedirectScheme() throws -> String {
        let trimmedClientID = configuration.clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientID.isEmpty else {
            throw AuthError.invalidRedirectURI("GOOGLE_CLIENT_ID is empty, so the Google callback scheme cannot be resolved")
        }

        return "\(Constants.schemePrefix)\(trimmedClientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: ""))"
    }

    private func makeAuthorizationURL(state: String, redirectURI: String, pkce: PKCEChallenge) throws -> URL {
        var components = URLComponents(url: Constants.authBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components?.url else {
            throw AuthError.invalidAuthorizationURL
        }
        return url
    }

    private func extractAuthorizationCode(from callbackURL: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidCallback
        }

        if let callbackError = components.queryItems?.first(where: { $0.name == "error" })?.value {
            let description = components.queryItems?.first(where: { $0.name == "error_description" })?.value
            let message = [callbackError, description]
                .compactMap { value in
                    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed?.isEmpty == false ? trimmed : nil
                }
                .joined(separator: " — ")
            throw AuthError.callbackRejected(message.isEmpty ? "Google sign-in callback returned an error" : "Google sign-in callback returned: \(message)")
        }

        let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        guard state == expectedState else {
            throw AuthError.invalidCallback
        }

        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.missingAuthorizationCode
        }

        return code
    }

    private func exchangeCodeForTokens(_ code: String, verifier: String, redirectURI: String) async throws -> GoogleTokenResponse {
        var request = URLRequest(url: Constants.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters: [String: String?] = [
            "code": code,
            "client_id": configuration.clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code",
            "code_verifier": verifier
        ]
        parameters["client_secret"] = normalizedClientSecret

        request.httpBody = formEncodedBody(parameters)

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data, context: "token exchange")
            return try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        } catch {
            throw mapTransportError(error)
        }
    }

    private func refreshAccessToken(using refreshToken: String) async throws -> GoogleStoredTokens {
        var request = URLRequest(url: Constants.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters: [String: String?] = [
            "client_id": configuration.clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        parameters["client_secret"] = normalizedClientSecret

        request.httpBody = formEncodedBody(parameters)

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data, context: "token refresh")
            let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
            let currentIDToken = try currentTokens()?.idToken

            let stored = GoogleStoredTokens(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? refreshToken,
                expiryDate: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
                idToken: tokenResponse.idToken ?? currentIDToken,
                accountEmail: try currentTokens()?.accountEmail
            )
            try persist(tokens: stored)
            return stored
        } catch {
            throw mapTransportError(error)
        }
    }

    private func store(response: GoogleTokenResponse) throws -> GoogleStoredTokens {
        guard let refreshToken = response.refreshToken else {
            throw AuthError.missingRefreshToken
        }

        let stored = GoogleStoredTokens(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiryDate: Date().addingTimeInterval(TimeInterval(response.expiresIn)),
            idToken: response.idToken,
            accountEmail: response.idToken.flatMap { GoogleIDTokenPayload.decode(from: $0)?.email }
        )
        try persist(tokens: stored)
        return stored
    }

    private func hydrateAccountEmail(for tokens: GoogleStoredTokens) async throws -> GoogleStoredTokens {
        if tokens.email != nil {
            return tokens
        }

        do {
            guard let fetchedEmail = try await fetchAccountEmail(accessToken: tokens.accessToken), !fetchedEmail.isEmpty else {
                return tokens
            }

            let hydrated = GoogleStoredTokens(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiryDate: tokens.expiryDate,
                idToken: tokens.idToken,
                accountEmail: fetchedEmail
            )
            try persist(tokens: hydrated)
            return hydrated
        } catch {
            return tokens
        }
    }

    private func fetchAccountEmail(accessToken: String) async throws -> String? {
        var request = URLRequest(url: Constants.userInfoURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data, context: "userinfo request")
            return try JSONDecoder().decode(GoogleUserInfoResponse.self, from: data).email
        } catch {
            throw mapTransportError(error)
        }
    }

    private var normalizedClientSecret: String? {
        let trimmed = configuration.clientSecret?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private func persist(tokens: GoogleStoredTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        try keychain.save(data, account: Constants.tokenAccount)
    }

    private func validate(response: URLResponse, data: Data, context: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard 200..<300 ~= http.statusCode else {
            if let message = decodeGoogleError(from: data) {
                throw AuthError.googleAPIError(context: context, message: message)
            }
            throw AuthError.googleHTTPError(context: context, statusCode: http.statusCode)
        }

        guard !data.isEmpty else {
            throw AuthError.invalidResponse
        }
    }

    private func decodeGoogleError(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(GoogleErrorResponse.self, from: data).summary
    }

    private func mapAuthenticationError(_ error: Error) -> Error {
        if let authError = error as? AuthError {
            return authError
        }

        if let sessionError = error as? ASWebAuthenticationSessionError {
            switch sessionError.code {
            case .canceledLogin:
                return AuthError.oauthCancelled
            case .presentationContextInvalid, .presentationContextNotProvided:
                return AuthError.authSessionFailed("Google sign-in could not present the authentication sheet")
            @unknown default:
                break
            }
        }

        let nsError = error as NSError
        if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
           let code = ASWebAuthenticationSessionError.Code(rawValue: nsError.code) {
            switch code {
            case .canceledLogin:
                return AuthError.oauthCancelled
            case .presentationContextInvalid, .presentationContextNotProvided:
                return AuthError.authSessionFailed("Google sign-in could not present the authentication sheet")
            @unknown default:
                break
            }
        }

        let transportError = mapTransportError(error)
        if let authError = transportError as? AuthError {
            return authError
        }

        return AuthError.authSessionFailed("Google sign-in failed: \(error.localizedDescription)")
    }

    private func mapTransportError(_ error: Error) -> Error {
        if let authError = error as? AuthError {
            return authError
        }

        if let urlError = extractURLError(from: error) {
            switch urlError.code {
            case .cannotFindHost, .dnsLookupFailed:
                return AuthError.cannotResolveGoogleHost
            case .notConnectedToInternet:
                return AuthError.networkUnavailable
            case .networkConnectionLost:
                return AuthError.networkConnectionLost
            default:
                break
            }
        }

        return error
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

    private func formEncodedBody(_ parameters: [String: String?]) -> Data? {
        let body = parameters
            .compactMap { key, value -> String? in
                guard let value else { return nil }
                return "\(percentEncode(key))=\(percentEncode(value))"
            }
            .joined(separator: "&")

        return body.data(using: .utf8)
    }

    private func percentEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: ":#[]@!$&'()*+,;="))) ?? string
    }

    private func makePKCEChallenge() -> PKCEChallenge {
        let verifier = randomURLSafeString(length: 64)
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return PKCEChallenge(verifier: verifier, challenge: challenge)
    }

    private func randomURLSafeString(length: Int) -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<length).map { _ in charset.randomElement()! })
    }
}

extension GoogleAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) ?? NSApp.windows.first ?? ASPresentationAnchor()
        }
    }
}
