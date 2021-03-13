//
// Created by utsman on 13/03/21.
//

import Foundation

protocol Response{}

struct Dropbox {

    static let clientId = "82wwpoqpguc75ti"
    static let clientSecret = "g03oy532yf04nu1"
    static let redirectUri = "https://utsmannn.github.io/callback"
    static let urlAuth = "https://www.dropbox.com/oauth2/authorize?client_id={client_id}&token_access_type=offline&response_type=code&redirect_uri={redirect_uri}"
    static let baseUrlToken = "https://api.dropbox.com"
    static let baseUrlApi = "https://api.dropboxapi.com/2"

    struct TokenResponse: Codable, Equatable, Response {
        let accessToken: String
        let expiresIn: Int
        let scope: String
        let tokenType: String
        let accountId: String
    }

    struct ProfileResponse: Codable, Equatable, Response {
        struct Name: Codable, Equatable {
            let familiarName: String
            let displayName: String
        }
        let name: Name
        let email: String
        let profilePhotoUrl: String
    }
}
