//
// Created by utsman on 13/03/21.
//

import Foundation

protocol CloudApi {
    func signIn()
    func getTokenResponse(using redirectUrl: URL, completion: @escaping (Result<TokenEntity, Error>) -> ())
    func getProfile(completion: @escaping (Result<ProfileEntity, Error>) -> ())
    func searchNoteFile(completion: @escaping (Result<FileEntity, Error>) -> ())
    func getNoteFile(completion: @escaping (Result<[NoteEntity], Error>) -> ())
    func upload(notes: [NoteEntity], completion: @escaping (Result<FileEntity, Error>) -> ())
}