//
// Created by utsman on 13/03/21.
//

import Foundation

struct TokenEntity: Equatable, Hashable {
    var accessToken: String
    var profileId: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(profileId)
    }

    static func ==(lhs: TokenEntity, rhs: TokenEntity) -> Bool {
        if lhs.accessToken != rhs.accessToken {
            return false
        }
        if lhs.profileId != rhs.profileId {
            return false
        }
        return true
    }
}