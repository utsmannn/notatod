//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

class GoogleSignInViewModel: NSObject, ObservableObject {
    var userDefaultController: UserDefaultController
    var driveController: GoogleDriveController
    var featureApiController: FeatureApiController

    @Published var logonStatus: LogonStatus = LogonStatus.not_sign_in

    @Published var profile: ProfileEntity?
    @Published var fileInfo: DriveResponse.FileInfo? = nil

    @Published var version: VersionResponse.MacOs?
    @Published var isUpdateAvailable: Bool = false
    @Published var isGoogleAuthEnable: Bool = true

    private let clientId = GoogleConfig.CLIENT_ID
    private let secretId = GoogleConfig.SECRET_ID

    private let redirectUri = GoogleConfig.REDIRECT_URI
    private let session = URLSession.shared

    init(userDefaultController: UserDefaultController, driveController: GoogleDriveController, featureApiController: FeatureApiController) {
        self.userDefaultController = userDefaultController
        self.driveController = driveController
        self.featureApiController = featureApiController
        super.init()
    }

    private var signInPageURL: URL {
        let scopes = "https://www.googleapis.com/auth/drive profile email"

        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.google.com"
        components.path = "/o/oauth2/auth"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "access_type", value: "online")
        ]
        return components.url!
    }

    private var networkProfile: Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: "https://oauth2.googleapis.com")
                .buildTask()
    }

    func getAccessToken() -> String? {
        guard let idToken = userDefaultController.idToken() else { return nil }
        requestProfile(idToken: idToken)
        return userDefaultController.accessToken()
    }

    func signIn() {
        let config = NSWorkspace.OpenConfiguration()
        config.promptsUserIfNeeded = true
        config.hides = true
        NSWorkspace.shared.open(signInPageURL, configuration: config) { application, error in
            NSApplication.shared.hide(self)
            if error != nil {
                log(error!)
            }
        }
    }

    private func code(from redirectURL: URL) -> String? {
        let components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }

    func getTokenResponse(using redirectUrl: URL, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        // Debug only for get code
        // set false for release
        let codeOnly = false

        guard let code = code(from: redirectUrl) else {
            completion(.failure(.code_not_found_in_redirect_URL))
            return
        }

        if !codeOnly {
            startNetworkTask(code: code, completion: completion)
        } else {
            log("code is -> \(code)")
        }
    }

    private func startNetworkTask(code: String, completion: @escaping (Result<TokenResponse, Error>) -> ()) {
        let params = [
            "code": code,
            "client_id": clientId,
            "client_secret": secretId,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ]

        let networkBuilder = NetworkBuilder(session: session)
                .baseUrl(url: "https://www.googleapis.com")
                .buildTask()

        networkBuilder?.request(path: "/oauth2/v4/token", method: .post)
                .addParams(params: params)
                .addContentType(contentType: .application_form_urlencoded)
                .start()
                .onSuccess { data in
                    log(data.asString())
                    do {
                        let response: TokenResponse = try data.decodeData()
                        self.userDefaultController.saveAccessToken(accessToken: response.accessToken)
                        self.userDefaultController.saveIdToken(idToken: response.idToken)
                        completion(.success(response))
                    } catch {
                        log(error)
                        completion(.failure(.decoding_error(error)))
                    }
                }.onFailure { error in
                    completion(.failure(error))
                }
    }

    func requestProfile(idToken: String) {
        networkProfile?.request(path: "/tokeninfo", method: .get)
                .addParam(key: "id_token", value: idToken)
                .start()
                .onSuccess { data in
                    do {
                        let profileResponse: ProfileResponse = try data.decodeData()
                        self.profile = profileResponse.mapToEntity()
                        self.logonStatus = .sign_in_success
                    } catch {
                        log("error decode: \(error)")
                        self.profile = nil
                        self.logonStatus = .sign_in_failed
                    }
                    log(data.asString())
                }.onFailure { error in
                    log(error)
                    self.logonStatus = .sign_in_failed
                }
    }

    func expectGoogleUserUrl(url: [URL]) -> (Bool, URL?) {
        let googleUrl = "com.googleusercontent.apps"
        let googleUrlFound = url.filter { url in
            url.absoluteString.contains(googleUrl)
        }.first

        let isGoogleUrl = googleUrlFound != nil
        return (isGoogleUrl, googleUrlFound)
    }

    func getFileInfoInDrive() {
        guard let fileId = userDefaultController.fileId() else { return }
        driveController.getFileInfo(fileId: fileId, onSuccess: { info in
            self.fileInfo = info
        }, onError: { error in
            self.fileInfo = nil
        })
    }

    func versionName() -> String {
        let versionName = NSApplication.shared.AppVersionName ?? "Unknown"
        let versionCode = NSApplication.shared.AppVersion ?? "Unknown"
        return "Version \(versionName) (\(versionCode))"
    }
}

enum LogonStatus : String {
    case sign_in_success = "Sign In successful"
    case sign_in_failed = "Sign In failed"
    case sign_in = "You has Sign In"
    case not_sign_in = "You not Sign In"
}