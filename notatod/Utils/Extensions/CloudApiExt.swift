//
// Created by utsman on 13/03/21.
//

import Foundation

extension CloudApi {
    func urlTypeChecking(url: URL) -> AuthTypeUrl<URL> {
        let googleUrlFound = url.absoluteString.contains(Google.redirectUri)
        let dropboxUrlFound = url.absoluteString.contains(Dropbox.redirectUri)

        if googleUrlFound {
            return .google(url)
        } else if dropboxUrlFound {
            return .dropbox(url)
        } else {
            return .none
        }
    }
}