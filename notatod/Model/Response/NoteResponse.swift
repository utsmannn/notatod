//
// Created by utsman on 03/03/21.
//

import Foundation

struct NoteResponse : Codable, Equatable {
    let id: String
    let title: String
    let body: String
    let dateMillis: Int
}