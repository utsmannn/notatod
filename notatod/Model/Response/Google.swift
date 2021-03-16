//
// Created by utsman on 13/03/21.
//

import Foundation

struct Google {

    static let clientId = "736390409372-imu2t0a2ojbn56abc6pj0q0iv1qjn59i"
    static let clientSecret = "NnbkdO1bk35LAozO3DIMuGh0"
    static let redirectUri = "com.googleusercontent.apps.736390409372-imu2t0a2ojbn56abc6pj0q0iv1qjn59i:/oauth2redirect/google"
    static let scope = "https://www.googleapis.com/auth/drive profile email"
    static let urlAuth = "https://accounts.google.com/o/oauth2/auth?client_id={client_id}&response_type=code&scope={scope}&redirect_uri={redirect_uri}&access_type=online"
    static let baseUrlApi = "https://www.googleapis.com"
    static let baseUrlProfile = "https://oauth2.googleapis.com"

    struct TokenResponse: Codable, Equatable {
        let accessToken: String
        let expiresIn: Int
        let idToken: String
        let scope: String
        let tokenType: String
        let refreshToken: String?
    }

    struct ProfileResponse : Codable, Equatable {
        let email: String
        let name: String
        let givenName: String
        let picture: String
    }

    struct FileResponse: Codable, Equatable {
        let name: String
        let id: String
    }

    struct FileInfoResponse: Codable, Equatable {
        let createdDate: String
        let modifiedDate: String
    }

    struct FilesResponse: Codable, Equatable {
        let files: [FileResponse]
    }
}