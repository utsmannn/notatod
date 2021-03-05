//
// Created by utsman on 03/03/21.
//

import Foundation

struct DriveResponse {
    struct Upload: Codable, Equatable {
        let kind: String
        let id: String
        let name: String?
        let mimeType: String
        let createdDate: String?
        let modifiedDate: String?
    }

    struct File: Codable, Equatable {
        let name: String
        let id: String
    }

    struct FileInfo: Codable, Equatable {
        let createdDate: String
        let modifiedDate: String
    }

    struct Files: Codable, Equatable {
        let files: [File]
    }
}
