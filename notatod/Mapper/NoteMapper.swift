//
// Created by utsman on 03/03/21.
//

import Foundation

struct NoteMapper {

    static func notesToTextCsv(notes: [NoteEntity]) -> String {
        let header = "id,date,title,body"
        var notesString = notes.map { entity -> String in
            "\(entity.id),\(entity.date.asMillisecond()),\(entity.title),\(entity.body)"
        }

        notesString.insert("\(header)", at: 0)
        let cvsFormatString = ("\(notesString)")
                .replacingOccurrences(of: "[\"", with: "")
                .replacingOccurrences(of: "\"]", with: "")
                .replacingOccurrences(of: "\", \"", with: "\n")

        return cvsFormatString
    }

    static func validateIsCsv(stringCsv: String, onValid: @escaping () -> (), onInvalid: @escaping (Error) -> ()) {
        let isValid = stringCsv.contains("id,date,title,body")
        if isValid {
            onValid()
        } else {
            let isInvalidCredential = stringCsv.contains("\"reason\": \"authError\",")
            if isInvalidCredential {
                onInvalid(.invalid_credential)
            } else  {
                onInvalid(.invalid_response)
            }
        }
    }

    static func stringCsvToNotes(stringCsv: String) -> [NoteEntity] {
        var result: [[String]] = []
        let rows = stringCsv.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }

        result.remove(at: 0)
        var noteResponses: [NoteResponse] = []
        for rawRow in result {
            let id = rawRow[0]
            let date = Int(rawRow[1]) ?? 0
            let title = rawRow[2]
            let body = rawRow[3]
            let noteResponse = NoteResponse(id: id, title: title, body: body, dateMillis: date)
            noteResponses.append(noteResponse)
        }

        return noteResponses.map { response -> NoteEntity in
            response.asNoteEntity()
        }
    }
}

extension NoteResponse {
    func asNoteEntity() -> NoteEntity {
        let date = Date(timeIntervalSince1970: TimeInterval(dateMillis))
        return NoteEntity(id: id, title: title, body: body, date: date)
    }
}