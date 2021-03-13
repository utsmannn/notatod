//
// Created by utsman on 13/03/21.
//

import Foundation

extension Google.TokenResponse {
    func mapToEntity() -> TokenEntity {
        TokenEntity(accessToken: accessToken, profileId: idToken)
    }
}

extension Dropbox.TokenResponse {
    func mapToEntity() -> TokenEntity {
        TokenEntity(accessToken: accessToken, profileId: accountId)
    }
}