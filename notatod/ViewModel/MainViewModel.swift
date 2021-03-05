//
// Created by utsman on 03/03/21.
//

import Foundation
import Combine

class MainViewModel: ObservableObject, Equatable {
    static func ==(lhs: MainViewModel, rhs: MainViewModel) -> Bool {
        lhs.notes == rhs.notes
    }

    @Published var notes = [NoteEntity]()
    @Published var selection: String?
    @Published var hasLogon: Bool?
    @Published var fontSize: Double = 16

    @Published var fileInfo: DriveResponse.FileInfo? = nil

    var driveController: DriveController
    var userDefaultController: UserDefaultController

    init(driveController: DriveController, userDefaultController: UserDefaultController) {
        self.driveController = driveController
        self.userDefaultController = userDefaultController
    }

    func setupInitializer(entities: [NoteEntity]) {
        notes = entities
    }

    func setSelectionId(selectionId: String) {
        selection = selectionId
    }

    func addNewNote(withSelectionId: Bool = true) {
        let blankNote = NoteEntity.addBlank(id: UUID().uuidString)
        notes.insert(blankNote, at: 0)
        if withSelectionId {
            setSelectionId(selectionId: blankNote.id)
        }
    }

    func removeNote(noteId: String) {
        let noteIds = notes.map { slice -> String in
            slice.id
        }

        guard let index = noteIds.findIndex(object: noteId) else {
            return
        }

        if notes.count == 1 {
            notes.remove(at: index)
            addNewNote(withSelectionId: false)
            setSelectionId(selectionId: notes[index].id)
        } else {
            notes.remove(at: index)
            var nextIndex = index
            if index == notes.count {
                nextIndex = index - 1
            }
            setSelectionId(selectionId: notes[nextIndex].id)
        }
    }

    func hasUploaded() -> Bool {
        userDefaultController.fileId() != nil
    }

    func uploadToDrive(status: @escaping (Bool) -> ()) {
        let csvContent = NoteMapper.notesToTextCsv(notes: notes)
        if userDefaultController.fileId() == nil {
            driveController.initialUpload(
                    body: csvContent,
                    onSuccess: { upload in
                        self.userDefaultController.saveFileId(fileId: upload.id)
                        status(true)
                    }, onError: { error in
                status(false)
                log(error)
            })
        } else {
            let csvContent = NoteMapper.notesToTextCsv(notes: notes)
            driveController.update(
                    fileId: userDefaultController.fileId()!,
                    body: csvContent,
                    onSuccess: { upload in
                        self.userDefaultController.saveFileId(fileId: upload.id)
                        status(true)
                    }, onError: { error in
                status(false)
                log(error)
            })
        }
    }

    func getFileInDrive(done: @escaping (Bool) -> ()) {
        log("file id ---> \(userDefaultController.fileId())")
        let fileId = userDefaultController.fileId()

        if userDefaultController.accessToken() == nil {
            done(false)
        } else {
            if fileId == nil {
                driveController.searchNoteFile(onSuccess: { file in
                    self.userDefaultController.saveFileId(fileId: file.id)
                    self.getFile(fileId: file.id, done: done)
                }, onError: { error in
                    done(false)
                })
            } else {
                getFile(fileId: fileId!, done: done)
            }
        }
    }

    private func getFile(fileId: String, done: @escaping (Bool) -> ()) {
        driveController.getFileCsv(fileId: fileId, onSuccess: { s in
            var entities = NoteMapper.stringCsvToNotes(stringCsv: s)
            let existingNote = self.userDefaultController.notes()

            for existing in existingNote {
                let exist = entities.map({ entity -> String in entity.body }).contains(existing.body)
                log("exis \(existing.title) --> \(exist)")
                if !exist {
                    entities.insert(existing, at: 0)
                }
            }

            self.userDefaultController.saveNotes(notes: entities)
            self.notes = self.userDefaultController.notes()
            self.setSelectionId(selectionId: self.notes[0].id)
            done(true)
        }, onError: { error in
            done(false)
            log(error)
        })
    }
}