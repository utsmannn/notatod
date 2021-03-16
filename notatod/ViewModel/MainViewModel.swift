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
    @Published var fileInfo: Google.FileInfoResponse? = nil

    @Published var isUpdateAvailable = false
    @Published var version: VersionResponse.MacOs?

    var cloudApi: CloudApi? = nil
    var cloudDefault: CloudUserDefault? = nil
    let userDefault = UserDefaultController()

    init(cloudApi: CloudApi?) {
        switch userDefault.authType() {
        case .google:
            cloudDefault = GoogleUserDefault()
        case .dropbox:
            cloudDefault = DropboxUserDefault()
        case .disable:
            cloudDefault = nil
        }

        self.cloudApi = cloudApi
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
        userDefault.fileId() != nil
    }

    func uploadToDrive(status: @escaping (Bool) -> ()) {
        cloudApi?.upload(notes: notes) { result in
            result.doOnSuccess { entity in
                log(entity)
            }
            result.doOnFailure { error in
                log(error)
            }
        }
    }

    func searchFileInDrive() {
        if hasLogon == true {
            cloudApi?.searchNoteFile { result in
                result.doOnSuccess { entity in
                    self.cloudDefault?.saveFileId(fileId: entity.id)
                    self.getFile()
                }
                result.doOnFailure { error in
                    self.setLocalNotes()
                }
            }
        } else {
            setLocalNotes()
        }
    }

    func setLocalNotes() {
        if userDefault.notes().isEmpty {
            notes = ConstantData.startingEntity()
        } else {
            notes = userDefault.notes()
        }
        setSelectionId(selectionId: notes[0].id)
    }

    private func getFile() {
        cloudApi?.getNoteFile { result in
            result.doOnSuccess { entities in
                self.notes = entities
                self.setSelectionId(selectionId: entities[0].id)
            }
            result.doOnFailure { error in
                log(error)
                self.setLocalNotes()
            }
        }
    }
}