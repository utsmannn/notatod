//
// Created by utsman on 13/03/21.
//

import Foundation

class DropboxUserDefault : CloudUserDefault {
    private let defaults = UserDefaults.standard

    static let TAG = "NOTATOD_DEFAULT"
    private let ACCESS_TOKEN = "\(TAG)_dropbox_access_token"
    private let ACCOUNT_ID = "\(TAG)_dropbox_account_id"

    func saveAccessToken(token: String) {
        defaults.set(token, forKey: ACCESS_TOKEN)
    }

    func saveAccountId(accountId: String) {
        defaults.set(accountId, forKey: ACCOUNT_ID)
    }

    func accessToken() -> String {
        defaults.string(forKey: ACCESS_TOKEN) ?? ""
    }

    func accountId() -> String {
        defaults.string(forKey: ACCOUNT_ID) ?? ""
    }
}
