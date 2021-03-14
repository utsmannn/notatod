//
// Created by utsman on 13/03/21.
//

import Foundation

extension Google.FileResponse {
    func mapToEntity() -> FileEntity {
        FileEntity(name: name, id: id)
    }
}

extension Dropbox.FileResponse {
    func mapToEntity() -> FileEntity {
        FileEntity(name: name, id: id)
    }
}