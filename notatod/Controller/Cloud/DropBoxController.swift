//
// Created by utsman on 12/03/21.
//

import Foundation
import SwiftUI

class DropboxController: CloudApi {
    enum Path: String {
        case token = "/oauth2/token"
        case profile = "/users/get_account"
    }

    private let dropboxUserDefault = DropboxUserDefault()

    private func signUrl() -> URL {
        let string = Dropbox.urlAuth.replacingOccurrences(of: "{client_id}", with: Dropbox.clientId)
                .replacingOccurrences(of: "{redirect_uri}", with: Dropbox.redirectUri)

        return URL(string: string)!
    }

    private func networkTaskApi() -> Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: Dropbox.baseUrlToken)
                .withAuthorization(authorization: dropboxUserDefault.accessToken())
                .buildTask(enableDebugPrint: true)
    }

    func signIn() {
        let config = NSWorkspace.OpenConfiguration()
        config.promptsUserIfNeeded = true
        config.hides = true
        NSWorkspace.shared.open(signUrl(), configuration: config) { application, error in
            NSApplication.shared.hide(self)
            if error != nil {
                log(error!)
            }
        }
    }

    func getTokenResponse(using redirectUrl: URL, completion: @escaping (Result<TokenEntity, Error>) -> Void) {
        let urlChecking = urlTypeChecking(url: redirectUrl)

        switch urlChecking {
        case .google:
            completion(.failure(.invalid_response))
        case .dropbox:
            let code = redirectUrl.code()
            let onlyCode = false
            if !onlyCode {
                getTokenTasks(code: code, completion: completion)
            } else {
                log("code --> \(code)")
            }
        case .none:
            completion(.failure(.invalid_response))
        }
    }

    private func getPath(path: Path) -> String {
        path.rawValue
    }

    private func getTokenTasks(code: String, completion: @escaping (Result<TokenEntity, Error>) -> ()) {
        let networkBuilder = NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: Dropbox.baseUrlToken)
                .buildTask(enableDebugPrint: true)

        networkBuilder?.request(path: getPath(path: .token), method: .post)
                .addParam(key: "code", value: code)
                .addParam(key: "client_id", value: Dropbox.clientId)
                .addParam(key: "client_secret", value: Dropbox.clientSecret)
                .addParam(key: "grant_type", value: "authorization_code")
                .addParam(key: "redirect_uri", value: Dropbox.redirectUri)
                .addContentType(contentType: .application_form_urlencoded)
                .start { result in
                    switch result {
                    case .success(let data):
                        log(data.asString())
                        do {
                            let response: Dropbox.TokenResponse = try data.decodeData()
                            self.dropboxUserDefault.saveAccessToken(token: response.accessToken)
                            self.dropboxUserDefault.saveAccountId(accountId: response.accountId)
                            completion(.success(response.mapToEntity()))
                            log("success....")
                        } catch {
                            log(error)
                            completion(.failure(.decoding_error(error)))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
    }

    func getProfile(completion: @escaping (Result<ProfileEntity, Error>) -> ()) {
        networkTaskApi()?.request(path: getPath(path: .profile), method: .post)
                .addParam(key: "account_id", value: dropboxUserDefault.accountId())
                .addContentType(contentType: .application_json)
                .start { result in
                    switch result {
                    case .success(let data):
                        do {
                            let response: Dropbox.ProfileResponse = try data.decodeData()
                            completion(.success(response.mapToEntity()))
                        } catch {
                            log(error)
                            completion(.failure(.decoding_error(error)))
                        }
                    case .failure(let error):
                        log("error")
                        completion(.failure(.network_error(error)))
                    }
                }
    }

    func searchNoteFile(completion: @escaping (Result<FileEntity, Error>) -> ()) {
        // hah
    }

    func getNoteFile(completion: @escaping (Result<[NoteEntity], Error>) -> ()) {
        //
    }

}