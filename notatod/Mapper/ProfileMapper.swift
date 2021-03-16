//
// Created by utsman on 03/03/21.
//

import Foundation

extension Google.ProfileResponse {
    func mapToEntity() -> ProfileEntity {
        ProfileEntity(email: email, name: name, givenName: givenName, pictureUrl: picture)
    }
}

extension Dropbox.ProfileResponse {
    func mapToEntity() -> ProfileEntity {
        ProfileEntity(email: email, name: name.displayName, givenName: name.displayName, pictureUrl: profilePhotoUrl ?? "")
    }
}