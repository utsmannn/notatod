//
// Created by utsman on 06/03/21.
//

import Foundation

extension VersionResponse.MacOs {

    func getChangelogEntity() -> [ChangelogEntity] {
        changelog.map { s -> ChangelogEntity in
            ChangelogEntity(desc: s)
        }
    }
}