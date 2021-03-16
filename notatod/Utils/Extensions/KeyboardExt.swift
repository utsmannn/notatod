//
// Created by utsman on 03/03/21.
//

import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openNote = Self("open_note", default: .init(.o, modifiers: [.command, .option, .control]))
    static let newNote = Self("new_note", default: .init(.n, modifiers: [.command, .option, .control]))
    static let saveNote = Self("save_note", default: .init(.s, modifiers: [.command, .option, .control]))
}