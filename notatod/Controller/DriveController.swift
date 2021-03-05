//
// Created by utsman on 03/03/21.
//

import Foundation

class DriveController {
    var accessToken: String?
    private let pathUpload = "/upload/drive/v3/files?uploadType=multipart"
    private let pathUpdate = "/upload/drive/v2/files"
    private let pathSearch = "/drive/v3/files"
    private let pathFile = "/drive/v2/files"

    private let semaphore = DispatchSemaphore(value: 0)

    private var networkTask: Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: "https://www.googleapis.com")
                .withAuthorization(authorization: "Bearer \(accessToken!)")
                .buildTask(enableDebugPrint: true)
    }

    /*private func pathGet(fileId: String) -> String {
        let path = "/drive/v2/files/{id}?alt=media&source=downloadUrl"
        return path.replacingOccurrences(of: "{id}", with: fileId)
    }*/

    private func contentBody(csvContent: String) -> String {
        "--foo_bar_baz\nContent-Type: application/json; charset=UTF-8\n\n{\n \"name\": \"{name}\"\n}\n\n--foo_bar_baz\nContent-Type: text/csv\n\n{body}\n--foo_bar_baz--"
                .replacingOccurrences(of: "{name}", with: "notatod_content")
                .replacingOccurrences(of: "{body}", with: csvContent)
    }

    func getFileCsv(
            fileId: String,
            onSuccess: @escaping (String) -> (),
            onError: @escaping (Error) -> ()
    ) {
        let externalPath = "?alt=media&source=downloadUrl"
        let path = "\(pathFile)/\(fileId)\(externalPath)"
        networkTask?.request(path: path, method: .get)
                .start()
                .onSuccess { data in
                    guard let stringResponse = String(data: data, encoding: .utf8) else {
                        return
                    }
                    NoteMapper.validateIsCsv(stringCsv: stringResponse, onValid: {
                        onSuccess(stringResponse)
                    }, onInvalid: { error in
                        onError(error)
                    })
                }.onFailure { error in
                    onError(Error.networkError(error))
                }
    }

    func getFileInfo(
            fileId: String,
            onSuccess: @escaping (DriveResponse.FileInfo) -> (),
            onError: @escaping (Error) -> ()
    ) {
        let path = "\(pathFile)/\(fileId)"
        networkTask?.request(path: path, method: .get)
                .start()
                .onSuccess { data in
                    log(String(data: data, encoding: .utf8)!)
                    do {
                        let response: DriveResponse.FileInfo = try data.decodeData()
                        onSuccess(response)
                    } catch {
                        onError(.decodingError(error))
                    }

                }.onFailure { error in
                    log(error)
                    onError(.networkError(error))
                }
    }

    private func requestUpload(
            contentBody: String,
            path: String,
            method: Method,
            onSuccess: @escaping (DriveResponse.Upload) -> (),
            onError: @escaping (Error) -> ()
    ) {
        if accessToken != nil {
            networkTask?.request(path: path, method: method)
                    .addContentType(contentType: .multipart_related_boundary)
                    .addRawBody(body: contentBody)
                    .start()
                    .onSuccess { data in
                        log(String(data: data, encoding: .utf8)!)
                        do {
                            let uploadResponse: DriveResponse.Upload = try data.decodeData()
                            onSuccess(uploadResponse)
                        } catch {
                            onError(.decodingError(error))
                        }
                    }.onFailure { error in
                        onError(.networkError(error))
                    }
        } else {
            onError(.invalidResponse)
        }
    }

    func searchNoteFile(
            onSuccess: @escaping (DriveResponse.File) -> (),
            onError: @escaping (Error) -> ()
    ) {
        networkTask?.request(path: pathSearch, method: .get)
                .start()
                .onSuccess { data in
                    log("mulaiiiiii--------------------------")
                    do {
                        let filesResponse: DriveResponse.Files = try data.decodeData()
                        let files = filesResponse.files
                        let mapToName = files.map { file -> String in
                            file.name
                        }
                        guard let index = mapToName.findIndex(object: "notatod_content") else { return }
                        let fileFound = files[index]
                        onSuccess(fileFound)
                    } catch {
                        log("error di sini......")
                        onError(.decodingError(error))
                    }
                }.onFailure { error in
                    log("hhhhhhhhhhhhhhh")
                    onError(.invalidResponse)
                }
    }

    func update(
            fileId: String,
            body: String,
            onSuccess: @escaping (DriveResponse.Upload) -> (),
            onError: @escaping (Error) -> ()
    ) {
        let path = "\(pathUpdate)/\(fileId)"
        let method: Method = .put
        let contentBody = self.contentBody(csvContent: body)
        requestUpload(
                contentBody: contentBody,
                path: path,
                method: method,
                onSuccess: onSuccess,
                onError: onError
        )
    }

    func initialUpload(
            body: String,
            onSuccess: @escaping (DriveResponse.Upload) -> (),
            onError: @escaping (Error) -> ()
    ) {
        let path = pathUpload
        let method: Method = .post
        let contentBody = self.contentBody(csvContent: body)
        requestUpload(
                contentBody: contentBody,
                path: path,
                method: method,
                onSuccess: onSuccess,
                onError: onError
        )
    }


}
