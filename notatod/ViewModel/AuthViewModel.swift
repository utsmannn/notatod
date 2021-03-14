//
// Created by utsman on 13/03/21.
//

import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    private let userDefaultController = UserDefaultController()
    private let featureApiController = FeatureApiController()
    private var cloudApi: CloudApi? = nil

    @Published var profile: ProfileEntity?
    @Published var hasLogon: Bool = false
    @Published var onProgress: Bool = false
    @Published var authType: AuthType = .disable

    init(cloudApi: CloudApi?) {
        self.cloudApi = cloudApi
    }

    func checkSession(onLogon: @escaping (ProfileEntity?) -> ()) {
        onProgress = true
        cloudApi?.getProfile { result in
            self.onProgress = false
            switch result {
            case .success(let profile):
                onLogon(profile)
                self.hasLogon = true
                self.profile = profile
            case .failure(let error):
                onLogon(nil)
                log(error)
                self.hasLogon = false
                self.profile = nil
            }
        }
    }

    func sign() {
        log("sign in...")
        cloudApi?.signIn()
    }
}