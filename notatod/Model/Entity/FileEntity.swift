//
// Created by utsman on 13/03/21.
//

import Foundation

struct FileEntity: Equatable, Hashable {
    var name: String
    var id: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(id)
    }

    static func ==(lhs: FileEntity, rhs: FileEntity) -> Bool {
        if lhs.name != rhs.name {
            return false
        }
        if lhs.id != rhs.id {
            return false
        }
        return true
    }
}