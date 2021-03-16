//
// Created by utsman on 12/03/21.
//

import Foundation
import SwiftUI

class DropboxController: CloudApi {
    enum Path: String {
        case token = "/oauth2/token"
        case profile = "/2/users/get_account"
        case search = "/2/files/list_folder"
        case file = "/2/files/download"
        case upload = "/2/files/upload"
    }

    private let dropboxUserDefault = DropboxUserDefault()
    private let userDefault = UserDefaultController()

    private func signUrl() -> URL {
        let string = Dropbox.urlAuth.replacingOccurrences(of: "{client_id}", with: Dropbox.clientId)
                .replacingOccurrences(of: "{redirect_uri}", with: Dropbox.redirectUri)

        return URL(string: string)!
    }

    private func networkTaskApi() -> Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: Dropbox.baseUrlToken)
                .withAuthorization(authorization: "Bearer \(dropboxUserDefault.accessToken())")
                .buildTask(enableDebugPrint: true)
    }

    private func networkTaskContent() -> Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: Dropbox.baseUrlUpload)
                .withAuthorization(authorization: "Bearer \(dropboxUserDefault.accessToken())")
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
        let rawBody = "{\n\"account_id\": \"\(dropboxUserDefault.accountId())\"\n}"
        networkTaskApi()?.request(path: getPath(path: .profile), method: .post)
                .addRawBody(body: rawBody)
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
        log("search ----")
        let rawBody = """
                      {\n    \"path\": \"\",\n
                      \"recursive\": false,\n
                      \"include_media_info\": false,\n
                      \"include_deleted\": false,\n
                      \"include_has_explicit_shared_members\": false,\n
                      \"include_mounted_folders\": true,\n
                      \"include_non_downloadable_files\": true\n}
                      """
        networkTaskApi()?.request(path: getPath(path: .search), method: .post)
                .addRawBody(body: rawBody)
                .start { result in
                    result.doOnSuccess { data in
                        log("success --> \(data)")
                        do {
                            let fileResponse: Dropbox.FilesResponses = try data.decodeData()
                            let files = fileResponse.entries
                            let mapToName = files.map { file -> String in
                                file.name
                            }
                            guard let index = mapToName.findIndex(object: "notatod_content.csv") else {
                                log("gak ada nihhh")
                                completion(.failure(.not_found))
                                return
                            }
                            let fileFound = files[index].mapToEntity()
                            completion(.success(fileFound))
                        } catch {
                            log(error)
                            completion(.failure(.decoding_error(error)))
                        }
                    }

                    result.doOnFailure { error in
                        log(error)
                        completion(.failure(error))
                    }
                }
    }

    func getNoteFile(completion: @escaping (Result<[NoteEntity], Error>) -> ()) {
        // code here
        let fileId = dropboxUserDefault.fileId()
        let stringArg = "{\"path\": \"\(fileId)\"}"
        networkTaskContent()?.request(path: getPath(path: .file), method: .post)
                .addContentType(contentType: .text_plain)
                .addValueHeader(key: "Dropbox-API-Arg", value: stringArg)
                .start { result in
                    result.doOnSuccess { data in
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
                    }

                    result.doOnFailure { error in
                        log(error)
                        completion(.failure(.network_error(error)))
                    }
                }
    }

    func upload(notes: [NoteEntity], completion: @escaping (Result<FileEntity, Error>) -> ()) {
        // code here
        let arg = "{\"path\": \"/notatod_content.csv\",\"mode\": \"overwrite\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}"
        let stringBody = NoteMapper.notesToTextCsv(notes: notes)
        networkTaskContent()?.request(path: getPath(path: .upload), method: .post)
                .addContentType(contentType: .application_octet_stream)
                .addValueHeader(key: "Dropbox-API-Arg", value: arg)
                .addRawBody(body: stringBody)
                .start { result in
                    result.doOnSuccess { data in
                        do {
                            let uploadResponse: Dropbox.FileResponse = try data.decodeData()
                            let fileEntity = uploadResponse.mapToEntity()
                            completion(.success(fileEntity))
                        } catch {
                            completion(.failure(.decoding_error(error)))
                        }
                    }

                    result.doOnFailure { error in
                        completion(.failure(.network_error(error)))
                    }
                }
    }

}