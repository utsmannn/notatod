import Foundation

struct GoogleDriveFile: Decodable, Sendable {
    let id: String
    let name: String
    let mimeType: String?
    let modifiedTime: String?
}

struct GoogleDriveFileListResponse: Decodable, Sendable {
    let files: [GoogleDriveFile]
}

struct GoogleDriveUploadResponse: Decodable, Sendable {
    let id: String
    let name: String?
}

struct GoogleDriveCreateFileRequest: Encodable, Sendable {
    let name: String
    let parents: [String]?
    let mimeType: String?
}

private struct GoogleDriveErrorResponse: Decodable {
    let error: GoogleDriveErrorPayload?

    struct GoogleDriveErrorPayload: Decodable {
        let code: Int?
        let message: String?
    }

    var message: String? {
        error?.message?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct GoogleDriveService {
    enum DriveError: Error, LocalizedError {
        case missingAccessToken
        case invalidResponse(context: String, statusCode: Int?, message: String?)
        case missingUploadLocation

        var errorDescription: String? {
            switch self {
            case .missingAccessToken:
                return "Google access token is missing"
            case .invalidResponse(let context, let statusCode, let message):
                let summary = message?.isEmpty == false ? message! : "Unknown Google Drive error"
                if let statusCode {
                    return "Google Drive \(context) failed with HTTP \(statusCode): \(summary)"
                }
                return "Google Drive \(context) failed: \(summary)"
            case .missingUploadLocation:
                return "Google Drive upload location is missing"
            }
        }
    }

    private let session: URLSession
    private let tokenProvider: @Sendable () async throws -> String?

    init(
        session: URLSession = .shared,
        tokenProvider: @escaping @Sendable () async throws -> String?
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
    }

    func createFolder(named name: String, parentID: String? = nil) async throws -> GoogleDriveUploadResponse {
        let body = GoogleDriveCreateFileRequest(
            name: name,
            parents: parentID.map { [$0] },
            mimeType: "application/vnd.google-apps.folder"
        )
        return try await createMetadata(body)
    }

    func listFiles(query: String? = nil, pageSize: Int = 100) async throws -> [GoogleDriveFile] {
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        var items = [
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,modifiedTime)")
        ]
        if let query {
            items.append(URLQueryItem(name: "q", value: query))
        }
        components.queryItems = items

        var request = try await authorizedRequest(url: components.url!)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, context: "list files")
        return try JSONDecoder().decode(GoogleDriveFileListResponse.self, from: data).files
    }

    func downloadFile(fileID: String) async throws -> Data {
        let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media")!
        var request = try await authorizedRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, context: "download file")
        return data
    }

    func uploadFile(
        named name: String,
        data: Data,
        mimeType: String = "application/octet-stream",
        parentID: String? = nil,
        existingFileID: String? = nil
    ) async throws -> GoogleDriveUploadResponse {
        let metadata = GoogleDriveCreateFileRequest(
            name: name,
            parents: existingFileID == nil ? parentID.map { [$0] } : nil,
            mimeType: nil
        )

        let boundary = "Boundary-\(UUID().uuidString)"
        var components = URLComponents(string: existingFileID == nil
            ? "https://www.googleapis.com/upload/drive/v3/files"
            : "https://www.googleapis.com/upload/drive/v3/files/\(existingFileID!)")!
        components.queryItems = [URLQueryItem(name: "uploadType", value: "multipart")]

        var request = try await authorizedRequest(url: components.url!)
        request.httpMethod = existingFileID == nil ? "POST" : "PATCH"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try multipartBody(boundary: boundary, metadata: metadata, data: data, mimeType: mimeType)

        let (responseData, response) = try await session.data(for: request)
        try validate(response: response, data: responseData, context: existingFileID == nil ? "create file" : "update file")
        return try JSONDecoder().decode(GoogleDriveUploadResponse.self, from: responseData)
    }

    func deleteFile(fileID: String) async throws {
        let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileID)")!
        var request = try await authorizedRequest(url: url)
        request.httpMethod = "DELETE"

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, context: "delete file", acceptedStatusCodes: [204])
    }

    private func createMetadata(_ body: GoogleDriveCreateFileRequest) async throws -> GoogleDriveUploadResponse {
        let url = URL(string: "https://www.googleapis.com/drive/v3/files")!
        var request = try await authorizedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, context: "create metadata")
        return try JSONDecoder().decode(GoogleDriveUploadResponse.self, from: data)
    }

    private func authorizedRequest(url: URL) async throws -> URLRequest {
        guard let token = try await tokenProvider() else {
            throw DriveError.missingAccessToken
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validate(
        response: URLResponse,
        data: Data,
        context: String,
        acceptedStatusCodes: Set<Int> = Set(200..<300)
    ) throws {
        guard let http = response as? HTTPURLResponse else {
            throw DriveError.invalidResponse(context: context, statusCode: nil, message: "Invalid HTTP response")
        }

        guard acceptedStatusCodes.contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(GoogleDriveErrorResponse.self, from: data).message)
                ?? String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw DriveError.invalidResponse(context: context, statusCode: http.statusCode, message: message)
        }
    }

    private func multipartBody(
        boundary: String,
        metadata: GoogleDriveCreateFileRequest,
        data: Data,
        mimeType: String
    ) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        let metadataData = try JSONEncoder().encode(metadata)

        body.append(Data("--\(boundary)\(lineBreak)".utf8))
        body.append(Data("Content-Type: application/json; charset=UTF-8\(lineBreak)\(lineBreak)".utf8))
        body.append(metadataData)
        body.append(Data(lineBreak.utf8))

        body.append(Data("--\(boundary)\(lineBreak)".utf8))
        body.append(Data("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".utf8))
        body.append(data)
        body.append(Data(lineBreak.utf8))
        body.append(Data("--\(boundary)--\(lineBreak)".utf8))

        return body
    }
}
