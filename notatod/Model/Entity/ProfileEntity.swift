//
// Created by utsman on 03/03/21.
//

import Foundation

class ProfileEntity : Identifiable, Equatable, Hashable {

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
        lhs.email != rhs.email
    }

    init(email: String, name: String, givenName: String, pictureUrl: String) {
        self.email = email
        self.name = name
        self.givenName = givenName
        self.pictureUrl = pictureUrl
    }
}
