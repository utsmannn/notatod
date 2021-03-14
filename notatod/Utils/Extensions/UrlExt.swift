//
// Created by utsman on 13/03/21.
//

import Foundation

extension URL {

    func code() -> String {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value ?? ""
    }
}