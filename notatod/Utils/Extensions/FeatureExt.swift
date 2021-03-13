//
// Created by utsman on 13/03/21.
//

import Foundation

extension FeatureResponse {
    func asAuthEnable() -> AuthEnable {
        switch cloudServiceEnable {
        case AuthType.google.enumAPI():
            return .google
        case AuthType.dropbox.enumAPI():
            return .dropbox
        default:
            return .disable
        }
    }
}