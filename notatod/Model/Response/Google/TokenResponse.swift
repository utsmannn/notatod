//
// Created by utsman on 03/03/21.
//

import Foundation

struct TokenResponse: Codable, Equatable {
    let accessToken: String
    let expiresIn: Int
    let idToken: String
    let scope: String
    let tokenType: String
    let refreshToken: String?
}