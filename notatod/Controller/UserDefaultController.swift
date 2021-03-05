//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

class UserDefaultController {
    private let defaults = UserDefaults.standard

    static let TAG = "NOTATOD_DEFAULT"
    private let ACCESS_TOKEN = "\(TAG)_access_token"
    private let ID_TOKEN = "\(TAG)_id_token"
    private let ID_FILE = "\(TAG)_file_id"
    private let NOTES = "\(TAG)_notes"
    private let THEMES = "\(TAG)_themes"

    func saveAccessToken(accessToken: String) {
        defaults.set(accessToken, forKey: ACCESS_TOKEN)
    }

    func accessToken() -> String? {
        defaults.string(forKey: ACCESS_TOKEN)
    }

    func saveIdToken(idToken: String) {
        defaults.set(idToken, forKey: ID_TOKEN)
    }

    func idToken() -> String? {
        defaults.string(forKey: ID_TOKEN)
    }

    func saveFileId(fileId: String) {
        defaults.set(fileId, forKey: ID_FILE)
    }

    func fileId() -> String? {
        defaults.string(forKey: ID_FILE)
    }

    func saveNotes(notes: [NoteEntity]) {
        let csvContent = NoteMapper.notesToTextCsv(notes: notes)
        defaults.set(csvContent, forKey: NOTES)
    }

    func notes() -> [NoteEntity] {
        let noteString = defaults.string(forKey: NOTES)
        var notes = [NoteEntity]()
        if noteString != nil {
            notes = NoteMapper.stringCsvToNotes(stringCsv: noteString!)
        }
        return notes
    }

    func setTheme(name: NSAppearance.Name?) {
        let nameString = name?.rawValue
        defaults.set(nameString, forKey: THEMES)
    }

    func theme() -> NSAppearance? {
        let savedTheme = defaults.string(forKey: THEMES)
        return stringToAppearance(nameString: savedTheme)
    }

    private func stringToAppearance(nameString: String?) -> NSAppearance? {
        switch (nameString) {
        case "NSAppearanceNameAqua":
            return NSAppearance(named: .aqua)
        case "NSAppearanceNameDarkAqua":
            return NSAppearance(named: .darkAqua)
        default:
            return nil
        }
    }
}