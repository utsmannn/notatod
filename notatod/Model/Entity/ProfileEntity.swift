//
// Created by utsman on 03/03/21.
//

import Foundation

struct ProfileEntity : Equatable, Hashable {

    var email: String
    var name: String
    var givenName: String
    var pictureUrl: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
        hasher.combine(name)
        hasher.combine(givenName)
        hasher.combine(pictureUrl)
    }

    static func ==(lhs: ProfileEntity, rhs: ProfileEntity) -> Bool {
        if lhs.email != rhs.email {
            return false
        }
        if lhs.name != rhs.name {
            return false
        }
        if lhs.givenName != rhs.givenName {
            return false
        }
        if lhs.pictureUrl != rhs.pictureUrl {
            return false
        }
        return true
    }
}
