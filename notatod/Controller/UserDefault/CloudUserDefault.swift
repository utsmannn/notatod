//
// Created by utsman on 13/03/21.
//

import Foundation

protocol CloudUserDefault {
    func saveAccessToken(token: String)
    func saveAccountId(accountId: String)
    func saveFileId(fileId: String)
    func accessToken() -> String
    func accountId() -> String
    func fileId() -> String
}