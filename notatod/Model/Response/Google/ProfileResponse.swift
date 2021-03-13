//
// Created by utsman on 03/03/21.
//

import Foundation

struct ProfileResponse : Codable, Equatable {
    let email: String
    let name: String
    let givenName: String
    let picture: String
}