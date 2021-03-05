//
// Created by utsman on 03/03/21.
//

import Foundation

extension ProfileResponse {
    func mapToEntity() -> ProfileEntity {
        ProfileEntity(email: email, name: name, givenName: givenName, pictureUrl: picture)
    }
}