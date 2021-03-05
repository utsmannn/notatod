//
// Created by utsman on 06/03/21.
//

import Foundation

struct VersionResponse : Codable, Equatable {
    let macOS : MacOs

    struct MacOs : Codable, Equatable {
        let versionCode: Int
        let versionName: String
        var changelog: [String] = [String]()
        let changelogString: String
        let downloadPage: String
    }
}