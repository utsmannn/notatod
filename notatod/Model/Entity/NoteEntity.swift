//
// Created by utsman on 03/03/21.
//

import Foundation

class NoteEntity : Identifiable, Equatable, Hashable {

    static func addBlank(id: String) -> NoteEntity {
        NoteEntity(id: id, title: "New note", body: "Body note ..", date: Date())
    }

    var id: String
    var title: String
    var body: String
    var date: Date

    init(id: String, title: String, body: String, date: Date) {
        self.id = id
        self.title = title
        self.body = body.replacingOccurrences(of: "\\n", with: "\n")
        self.date = date
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(body)
        hasher.combine(date)
    }

    static func ==(lhs: NoteEntity, rhs: NoteEntity) -> Bool {
        if lhs === rhs {
            return true
        }
        if type(of: lhs) != type(of: rhs) {
            return false
        }
        if lhs.id != rhs.id {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        if lhs.body != rhs.body {
            return false
        }
        if lhs.date != rhs.date {
            return false
        }
        return true
    }
}
