//
// Created by utsman on 13/03/21.
//

import Foundation

class GoogleUserDefault : CloudUserDefault {
    private let defaults = UserDefaults.standard

    static let TAG = "NOTATOD_DEFAULT"
    private let ACCESS_TOKEN = "\(TAG)_google_access_token"
    private let ACCOUNT_ID = "\(TAG)_google_account_id"
    private let FILE_ID = "\(TAG)_google_file_id"

    func saveAccessToken(token: String) {
        defaults.set(token, forKey: ACCESS_TOKEN)
    }

    func saveAccountId(accountId: String) {
        defaults.set(accountId, forKey: ACCOUNT_ID)
    }

    func saveFileId(fileId: String) {
        defaults.set(fileId, forKey: FILE_ID)
    }

    func accessToken() -> String {
        defaults.string(forKey: ACCESS_TOKEN) ?? ""
    }

    func accountId() -> String {
        defaults.string(forKey: ACCOUNT_ID) ?? ""
    }

    func fileId() -> String {
        defaults.string(forKey: FILE_ID) ?? ""
    }
}