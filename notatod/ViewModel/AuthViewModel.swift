//
// Created by utsman on 13/03/21.
//

import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    private let userDefaultController = UserDefaultController()
    private let featureApiController = FeatureApiController()
    private var cloudApi: CloudApi

    @Published var profile: ProfileEntity?
    @Published var onProgress: Bool = false

    init(cloudApi: CloudApi) {
        self.cloudApi = cloudApi
    }

    func checkSession() {
        onProgress = true
        cloudApi.getProfile { result in
            self.onProgress = false
            switch result {
            case .success(let profile):
                self.profile = profile
            case .failure(let error):
                log(error)
                self.profile = nil
            }
        }
    }

    func sign() {
        cloudApi.signIn()
    }
}