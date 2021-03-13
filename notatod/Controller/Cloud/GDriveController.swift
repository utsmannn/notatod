//
// Created by utsman on 13/03/21.
//

import Foundation
import SwiftUI

class GDriveController: CloudApi {
    private func signUrl() -> URL {
        let string = Google.urlAuth.replacingOccurrences(of: "{client_id}", with: Google.clientId)
                .replacingOccurrences(of: "{scope}", with: Google.scope)
                .replacingOccurrences(of: "{redirect_uri}", with: Google.redirectUri)
                .replacingOccurrences(of: " ", with: "%20")
        return URL(string: string)!
    }

    enum Path: String {
        case token = "/oauth2/v4/token"
        case profile = "/tokeninfo"
        case search = "/drive/v3/files"
        case file = "/drive/v2/files"
    }

    private let googleUserDefault = GoogleUserDefault()
    private let userDefault = UserDefaultController()

    private func getPath(path: Path) -> String {
        path.rawValue
    }

    private var networkTask: Network.NetworkTask? {
        let accessToken = googleUserDefault.accessToken()
        return NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: Google.baseUrlApi)
                .withAuthorization(authorization: "Bearer \(accessToken)")
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

    func getTokenResponse(using redirectUrl: URL, completion: @escaping (Result<TokenEntity, Error>) -> ()) {
        let code = redirectUrl.code()
        let onlyCode = false
        if !onlyCode {
            getTokenTasks(code: code, completion: completion)
        } else {
            log("code --> \(code)")
        }
    }

    private func getTokenTasks(code: String, completion: @escaping (Result<TokenEntity, Error>) -> ()) {
        networkTask?.request(path: getPath(path: .token), method: .post)
                .addParam(key: "code", value: code)
                .addParam(key: "client_id", value: Google.clientId)
                .addParam(key: "client_secret", value: Google.clientSecret)
                .addParam(key: "grant_type", value: "authorization_code")
                .addParam(key: "redirect_uri", value: Google.redirectUri)
                .addContentType(contentType: .application_form_urlencoded)
                .start()
                .onSuccess { data in
                    log(data.asString())
                    do {
                        let response: Google.TokenResponse = try data.decodeData()
                        self.googleUserDefault.saveAccessToken(token: response.accessToken)
                        self.googleUserDefault.saveAccountId(accountId: response.idToken)
                        completion(.success(response.mapToEntity()))
                    } catch {
                        log(error)
                        completion(.failure(.decoding_error(error)))
                    }
                }.onFailure { error in
                    completion(.failure(error))
                }
    }

    func getProfile(completion: @escaping (Result<ProfileEntity, Error>) -> ()) {
        let networkTaskProfile = NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: Google.baseUrlProfile)
                .buildTask()

        networkTaskProfile?.request(path: getPath(path: .profile), method: .get)
                .addParam(key: "id_token", value: googleUserDefault.accountId())
                .start { result in
                    switch result {
                    case .success(let data):
                        do {
                            let profileResponse: Google.ProfileResponse = try data.decodeData()
                            completion(.success(profileResponse.mapToEntity()))
                        } catch {
                            completion(.failure(.decoding_error(error)))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
    }

    func searchNoteFile(completion: @escaping (Result<FileEntity, Error>) -> ()) {
        networkTask?.request(path: getPath(path: .search), method: .get)
                .start { result in
                    switch result {
                    case .success(let data):
                        do {
                            let filesResponse: DriveResponse.Files = try data.decodeData()
                            let files = filesResponse.files
                            let mapToName = files.map { file -> String in
                                file.name
                            }
                            guard let index = mapToName.findIndex(object: "notatod_content") else {
                                return
                            }
                            let fileFound = files[index].mapToEntity()
                            completion(.success(fileFound))
                        } catch {
                            completion(.failure(.decoding_error(error)))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
    }

    func getNoteFile(completion: @escaping (Result<[NoteEntity], Error>) -> ()) {
        let externalPath = "?alt=media&source=downloadUrl"
        let fileId = userDefault.fileId() ?? ""
        let path = "\(getPath(path: .file))/\(fileId)\(externalPath)"
        networkTask?.request(path: path, method: .get)
                .start { result in
                    switch result {
                    case .success(let data):
                        guard let stringResponse = String(data: data, encoding: .utf8) else {
                            return
                        }
                        NoteMapper.validateIsCsv(stringCsv: stringResponse, onValid: {
                            var entities = NoteMapper.stringCsvToNotes(stringCsv: stringResponse)
                            let existingNote = self.userDefault.notes()

                            for existing in existingNote {
                                let exist = entities.map({ entity -> String in entity.body }).contains(existing.body)
                                if !exist {
                                    entities.insert(existing, at: 0)
                                }
                            }
                            self.userDefault.saveNotes(notes: entities)
                            let newEntity = self.userDefault.notes()
                            completion(.success(newEntity))
                        }, onInvalid: { error in
                            completion(.failure(.invalid_credential))
                        })
                    case .failure(let error):
                        log(error)
                        completion(.failure(.network_error(error)))
                    }
                }
    }

}