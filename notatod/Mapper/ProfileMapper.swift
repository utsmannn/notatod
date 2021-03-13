//
// Created by utsman on 03/03/21.
//

import Foundation

extension ProfileResponse {
    func mapToEntity() -> ProfileEntity {
        ProfileEntity(email: email, name: name, givenName: givenName, pictureUrl: picture)
    }
}

extension Google.ProfileResponse {
    func mapToEntity() -> ProfileEntity {
        ProfileEntity(email: email, name: name, givenName: givenName, pictureUrl: picture)
    }
}

extension Dropbox.ProfileResponse {
    func mapToEntity() -> ProfileEntity {
        ProfileEntity(email: email, name: name.familiarName, givenName: name.displayName, pictureUrl: profilePhotoUrl)
    }
}