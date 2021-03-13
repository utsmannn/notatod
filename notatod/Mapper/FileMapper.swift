//
// Created by utsman on 13/03/21.
//

import Foundation

extension DriveResponse.File {
    func mapToEntity() -> FileEntity {
        FileEntity(name: name, id: id)
    }
}