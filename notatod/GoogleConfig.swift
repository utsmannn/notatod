//
// Created by utsman on 03/03/21.
//

import Foundation

enum GoogleConfig {


    static let CLIENT_ID: String = {
        guard let key = GoogleConfig.infoDictionary["ClientID"] as? String else {
            fatalError("Client id not set in plist for this environment")
        }
        return key
    }()

    static let SECRET_ID: String = {
        guard let key = GoogleConfig.infoDictionary["SecretID"] as? String else {
            fatalError("Secret id not set in plist for this environment")
        }
        return key
    }()

    static let REDIRECT_URI = "com.googleusercontent.apps.\(CLIENT_ID):/oauth2redirect/google"

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()

}